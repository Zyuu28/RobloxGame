--!strict
--[[
	MonsterService — Biome Guardian Monsters & Safezone Barrier.
	Authority: GDD §3, §4, §5 & Steal Pursuit Mechanics.
	
	Behavior Specifications:
	  - Safezone forcefield perimeter (R = 120 studs). Inside = 100% immune.
	  - Monsters are STANDBY at 1 fixed post in their biome from the start.
	  - Monsters ONLY move/chase when a Mystery Box is stolen/carried outside Safezone.
	  - When box is dropped or carrier enters Safezone:
	      a) If another player is carrying a box outside Safezone -> retarget & chase them!
	      b) If no carriers -> monster physically walks back to its standby post (RETURNING).
	  - When monster reaches standby post -> enters STANDBY (guarding) mode.
	  - If player is caught -> box is dropped on the ground, player knocked back, monster brief cooldown.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)

local MonsterService = {}

local SAFEZONE_RADIUS = 120 -- studs from world center (0, 0, 0)

type MonsterConfig = {
	id: string,
	name: string,
	biome: string,
	standbyPos: Vector3,
	speed: number,
	themeColor: Color3,
}

local MONSTER_CONFIGS: { MonsterConfig } = {
	{
		id = "Urban_Monster",
		name = "Urban Security Drone",
		biome = "Urban",
		standbyPos = Vector3.new(-150, 1.5, 150),
		speed = 20,
		themeColor = Color3.fromRGB(0, 190, 255),
	},
	{
		id = "Slums_Monster",
		name = "Scrap Junkyard Beast",
		biome = "Slums",
		standbyPos = Vector3.new(-150, 1.5, -150),
		speed = 19,
		themeColor = Color3.fromRGB(240, 120, 40),
	},
}

type MonsterInstance = {
	id: string,
	name: string,
	biome: string,
	standbyPos: Vector3,
	speed: number,
	themeColor: Color3,
	model: Model,
	humanoid: Humanoid,
	primaryPart: Part,
	label: TextLabel,
	state: "STANDBY" | "CHASING" | "RETURNING" | "COOLDOWN",
	currentTarget: Player?,
	cooldownUntil: number,
	lastMovePos: Vector3,
	stuckTime: number,
}

local activeMonsters: { MonsterInstance } = {}
local CarryService: any = nil
local monstersFolder: Folder? = nil

function MonsterService.IsInSafezone(pos: Vector3): boolean
	local distFromCenter = math.sqrt(pos.X * pos.X + pos.Z * pos.Z)
	return distFromCenter <= SAFEZONE_RADIUS
end

local function buildSafezoneBarrier(parent: Instance)
	local barrierFolder = Instance.new("Folder")
	barrierFolder.Name = "SafezoneBarrier"
	barrierFolder.Parent = parent

	-- Visual glowing perimeter ring (24 segments for a smooth circle)
	local segments = 24
	for i = 1, segments do
		local angle1 = (i - 1) * (2 * math.pi / segments)
		local angle2 = i * (2 * math.pi / segments)

		local p1 = Vector3.new(math.cos(angle1) * SAFEZONE_RADIUS, 0.4, math.sin(angle1) * SAFEZONE_RADIUS)
		local p2 = Vector3.new(math.cos(angle2) * SAFEZONE_RADIUS, 0.4, math.sin(angle2) * SAFEZONE_RADIUS)
		local mid = (p1 + p2) / 2
		local length = (p1 - p2).Magnitude

		local line = Instance.new("Part")
		line.Name = "BarrierSegment_" .. i
		line.Size = Vector3.new(1.2, 0.8, length)
		line.CFrame = CFrame.lookAt(mid, p2)
		line.Anchored = true
		line.CanCollide = false
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(0, 220, 255)
		line.Parent = barrierFolder

		-- Holographic boundary posts at 4 cardinal entrances
		if i == 1 or i == 7 or i == 13 or i == 19 then
			local post = Instance.new("Part")
			post.Name = "BarrierPost_" .. i
			post.Size = Vector3.new(2, 10, 2)
			post.Position = p1 + Vector3.new(0, 5, 0)
			post.Anchored = true
			post.CanCollide = false
			post.Material = Enum.Material.Neon
			post.Color = Color3.fromRGB(0, 220, 255)
			post.Parent = barrierFolder

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 200, 0, 36)
			bb.StudsOffset = Vector3.new(0, 6, 0)
			bb.Adornee = post
			bb.Parent = post

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
			lbl.BackgroundTransparency = 0.2
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 12
			lbl.TextColor3 = Color3.fromRGB(0, 220, 255)
			lbl.Text = "🛡️ SAFEZONE BARRIER\nNO MONSTERS ENTER"
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = lbl
			lbl.Parent = bb
		end
	end
end

local function setBillboardState(monster: MonsterInstance, state: string, extraName: string?)
	if not monster.label then return end

	if state == "STANDBY" then
		monster.label.Text = "💤 " .. monster.name .. "\n[STANDBY - GUARDING]"
		monster.label.TextColor3 = monster.themeColor
	elseif state == "CHASING" then
		local targetText = if extraName then extraName else "CARRIER"
		monster.label.Text = "🔥 CHASING " .. targetText .. "!\n[STEAL PURSUIT!]"
		monster.label.TextColor3 = Color3.fromRGB(255, 45, 45)
	elseif state == "RETURNING" then
		monster.label.Text = "🚶 RETURNING TO POST\n[DISENGAGING]"
		monster.label.TextColor3 = Color3.fromRGB(255, 185, 50)
	elseif state == "COOLDOWN" then
		monster.label.Text = "💥 CAUGHT TARGET!\n[RELOADING]"
		monster.label.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

local function buildMonsterModel(cfg: MonsterConfig, parent: Instance): MonsterInstance
	local model = Instance.new("Model")
	model.Name = cfg.name

	-- Main Torso / Chassis
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(3.6, 4.2, 3.6)
	body.Position = cfg.standbyPos + Vector3.new(0, 3, 0)
	body.Material = Enum.Material.Neon
	body.Color = cfg.themeColor
	body.CanCollide = true
	body.Anchored = false
	body.Parent = model

	-- Keep monster upright at all times (prevent tilting/flipping)
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "UprightGyro"
	bodyGyro.MaxTorque = Vector3.new(1e6, 0, 1e6)
	bodyGyro.P = 15000
	bodyGyro.CFrame = CFrame.new()
	bodyGyro.Parent = body

	-- Glowing Eye / Visor
	local eye = Instance.new("Part")
	eye.Name = "MonsterEye"
	eye.Size = Vector3.new(2.2, 0.8, 0.6)
	eye.Material = Enum.Material.Neon
	eye.Color = Color3.fromRGB(255, 30, 30)
	eye.CanCollide = false
	eye.Parent = model

	local eyeWeld = Instance.new("Weld")
	eyeWeld.Part0 = body
	eyeWeld.Part1 = eye
	eyeWeld.C0 = CFrame.new(0, 0.8, -1.85)
	eyeWeld.Parent = eye

	-- Left and Right Side Stabilizers / Thrusters
	local leftThruster = Instance.new("Part")
	leftThruster.Name = "LeftThruster"
	leftThruster.Size = Vector3.new(1, 2.5, 1.5)
	leftThruster.Material = Enum.Material.Metal
	leftThruster.Color = Color3.fromRGB(40, 45, 55)
	leftThruster.CanCollide = false
	leftThruster.Parent = model

	local leftWeld = Instance.new("Weld")
	leftWeld.Part0 = body
	leftWeld.Part1 = leftThruster
	leftWeld.C0 = CFrame.new(-2.2, -0.5, 0)
	leftWeld.Parent = leftThruster

	local rightThruster = Instance.new("Part")
	rightThruster.Name = "RightThruster"
	rightThruster.Size = Vector3.new(1, 2.5, 1.5)
	rightThruster.Material = Enum.Material.Metal
	rightThruster.Color = Color3.fromRGB(40, 45, 55)
	rightThruster.CanCollide = false
	rightThruster.Parent = model

	local rightWeld = Instance.new("Weld")
	rightWeld.Part0 = body
	rightWeld.Part1 = rightThruster
	rightWeld.C0 = CFrame.new(2.2, -0.5, 0)
	rightWeld.Parent = rightThruster

	-- Floating Billboard Name & Status
	local bb = Instance.new("BillboardGui")
	bb.Name = "StatusBillboard"
	bb.Size = UDim2.new(0, 210, 0, 44)
	bb.StudsOffset = Vector3.new(0, 4.6, 0)
	bb.Adornee = body
	bb.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = cfg.themeColor
	label.Text = "💤 " .. cfg.name .. "\n[STANDBY - GUARDING]"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	label.Parent = bb

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = cfg.speed
	humanoid.HipHeight = 2.0 -- Smooth ground clearance
	humanoid.MaxHealth = 999999
	humanoid.Health = 999999
	humanoid.Parent = model

	model.PrimaryPart = body
	model.Parent = parent

	return {
		id = cfg.id,
		name = cfg.name,
		biome = cfg.biome,
		standbyPos = cfg.standbyPos,
		speed = cfg.speed,
		themeColor = cfg.themeColor,
		model = model,
		humanoid = humanoid,
		primaryPart = body,
		label = label,
		state = "STANDBY",
		currentTarget = nil,
		cooldownUntil = 0,
		lastMovePos = cfg.standbyPos,
		stuckTime = 0,
	}
end

--- Find the best candidate player who is carrying a mystery box outside the safezone.
local function findBestCarrierTarget(monster: MonsterInstance): Player?
	local monsterPos = monster.primaryPart.Position
	local closestPlayer: Player? = nil
	local closestDist = math.huge

	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp then
			local pPos = hrp.Position
			-- Must be OUTSIDE the Safezone
			if not MonsterService.IsInSafezone(pPos) then
				-- Must be carrying a Mystery Box
				if CarryService and CarryService.IsCarrying(p) then
					local dist = (monsterPos - pPos).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPlayer = p
					end
				end
			end
		end
	end

	return closestPlayer
end

--- Called immediately when any player picks up a mystery box.
function MonsterService.OnBoxPickedUp(player: Player, biomeId: string)
	-- Look for the monster of this biome first, or any monster in STANDBY/RETURNING
	local chosenMonster: MonsterInstance? = nil

	for _, m in ipairs(activeMonsters) do
		if m.biome == biomeId and (m.state == "STANDBY" or m.state == "RETURNING") then
			chosenMonster = m
			break
		end
	end

	-- If not found, pick any available monster
	if not chosenMonster then
		for _, m in ipairs(activeMonsters) do
			if m.state == "STANDBY" or m.state == "RETURNING" then
				chosenMonster = m
				break
			end
		end
	end

	if chosenMonster and player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and not MonsterService.IsInSafezone(hrp.Position) then
			chosenMonster.state = "CHASING"
			chosenMonster.currentTarget = player
			setBillboardState(chosenMonster, "CHASING", player.Name)
			chosenMonster.humanoid:MoveTo(hrp.Position)

			local notify = Network.GetEvent(Network.Events.NotifyFeedback)
			notify:FireClient(player, "🚨 " .. chosenMonster.name .. " spotted you! Run to Safezone!", "Warning")
			print("[MonsterService] " .. chosenMonster.name .. " started chasing " .. player.Name)
		end
	end
end

--- Called when a player drops or loses their mystery box.
function MonsterService.OnBoxDropped(player: Player)
	for _, monster in ipairs(activeMonsters) do
		if monster.currentTarget == player then
			-- Current target dropped their box!
			-- Check if another carrier is available outside safezone
			local nextTarget = findBestCarrierTarget(monster)
			if nextTarget and nextTarget ~= player then
				monster.currentTarget = nextTarget
				setBillboardState(monster, "CHASING", nextTarget.Name)

				local notify = Network.GetEvent(Network.Events.NotifyFeedback)
				notify:FireClient(nextTarget, "🚨 " .. monster.name .. " redirected and is chasing YOU!", "Warning")
				print("[MonsterService] " .. monster.name .. " redirected chase to " .. nextTarget.Name)
			else
				-- No one else is carrying a box outside safezone -> walk back to standby!
				monster.state = "RETURNING"
				monster.currentTarget = nil
				setBillboardState(monster, "RETURNING")
				monster.humanoid:MoveTo(monster.standbyPos)
				print("[MonsterService] " .. monster.name .. " returning to standby post.")
			end
		end
	end
end

-- Backward compatibility aliases
MonsterService.SpawnChaseMonster = MonsterService.OnBoxPickedUp
MonsterService.DespawnMonster = MonsterService.OnBoxDropped
MonsterService.OnBoxCleared = MonsterService.OnBoxDropped

function MonsterService.Init()
	print("[MonsterService] Initialized (Standby Guardians & Return Mode).")
end

function MonsterService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	CarryService = require(servicesFolder:WaitForChild("CarryService") :: ModuleScript)

	local worldFolder = Workspace:FindFirstChild("World")
	if not worldFolder then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = "World"
		worldFolder.Parent = Workspace
	end

	-- 1. Construct Safezone Forcefield Barrier (R = 120 studs)
	buildSafezoneBarrier(worldFolder)

	-- 2. Spawn Guardian Monsters at their standby points
	monstersFolder = Instance.new("Folder")
	monstersFolder.Name = "BiomeMonsters"
	monstersFolder.Parent = worldFolder

	for _, cfg in ipairs(MONSTER_CONFIGS) do
		local monster = buildMonsterModel(cfg, monstersFolder)
		table.insert(activeMonsters, monster)
		print("[MonsterService] Spawned " .. cfg.name .. " at standby post: " .. tostring(cfg.standbyPos))
	end

	-- 3. Monster Autonomous AI Loop (Runs every 0.3s)
	task.spawn(function()
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)

		while true do
			task.wait(0.3)
			local now = os.clock()

			for _, monster in ipairs(activeMonsters) do
				if not monster.model.Parent or not monster.primaryPart then continue end

				local monsterPos = monster.primaryPart.Position

				------------------------------------------------------
				-- State: COOLDOWN (Just caught a target, brief pause)
				------------------------------------------------------
				if monster.state == "COOLDOWN" then
					if now >= monster.cooldownUntil then
						-- Cooldown finished. Search for any active carrier!
						local nextTarget = findBestCarrierTarget(monster)
						if nextTarget then
							monster.state = "CHASING"
							monster.currentTarget = nextTarget
							setBillboardState(monster, "CHASING", nextTarget.Name)
						else
							monster.state = "RETURNING"
							monster.currentTarget = nil
							setBillboardState(monster, "RETURNING")
							monster.humanoid:MoveTo(monster.standbyPos)
						end
					end
					continue
				end

				------------------------------------------------------
				-- State: STANDBY (Guarding post, waiting for theft)
				------------------------------------------------------
				if monster.state == "STANDBY" then
					local target = findBestCarrierTarget(monster)
					if target and target.Character then
						local hrp = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if hrp then
							monster.state = "CHASING"
							monster.currentTarget = target
							setBillboardState(monster, "CHASING", target.Name)
							monster.humanoid:MoveTo(hrp.Position)

							notify:FireClient(target, "🚨 " .. monster.name .. " spotted you! Run to Safezone!", "Warning")
						end
					else
						-- Ensure monster remains stationed at standby post
						if (monsterPos - monster.standbyPos).Magnitude > 3.0 then
							monster.humanoid:MoveTo(monster.standbyPos)
						end
					end

				------------------------------------------------------
				-- State: CHASING (Actively pursuing a carrier)
				------------------------------------------------------
				elseif monster.state == "CHASING" then
					local target = monster.currentTarget
					local isValid = false
					local targetHrp: BasePart? = nil
					local targetPos: Vector3? = nil

					if target and target.Parent and target.Character then
						targetHrp = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if targetHrp then
							targetPos = targetHrp.Position
							local isCarrying = CarryService and CarryService.IsCarrying(target)
							local inSafezone = MonsterService.IsInSafezone(targetPos)

							-- Target remains valid only if carrying AND outside Safezone!
							if isCarrying and not inSafezone then
								isValid = true
							end
						end
					end

					if isValid and targetPos and targetHrp and target then
						-- Valid chase! Move towards player
						monster.humanoid:MoveTo(targetPos)

						-- Check if caught player (within 5.8 studs)
						local dist = (monsterPos - targetPos).Magnitude
						if dist <= 5.8 then
							-- CAUGHT!
							monster.state = "COOLDOWN"
							monster.cooldownUntil = now + 2.5
							setBillboardState(monster, "COOLDOWN")

							notify:FireClient(target, "💥 " .. monster.name .. " caught you! Box dropped!", "Error")

							-- Drop the carried box onto the ground right here!
							if CarryService then
								CarryService.DropBox(target)
							end

							-- Push player away
							local pushDir = (targetPos - monsterPos).Unit
							targetHrp.AssemblyLinearVelocity = pushDir * 35 + Vector3.new(0, 16, 0)
						end
					else
						-- Target is no longer valid (dropped box, reached safezone, died, or disconnected)
						if target and target.Character then
							local hrp = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
							if hrp and MonsterService.IsInSafezone(hrp.Position) then
								notify:FireClient(target, "🛡️ You reached the Safezone! Monster disengaged.", "Success")
							end
						end

						-- Check if another player is carrying a box outside safezone!
						local altTarget = findBestCarrierTarget(monster)
						if altTarget and altTarget.Character then
							local altHrp = altTarget.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
							if altHrp then
								monster.currentTarget = altTarget
								setBillboardState(monster, "CHASING", altTarget.Name)
								monster.humanoid:MoveTo(altHrp.Position)
								notify:FireClient(altTarget, "🚨 " .. monster.name .. " switched target to YOU!", "Warning")
							end
						else
							-- No other carriers -> Walk back to standby post!
							monster.state = "RETURNING"
							monster.currentTarget = nil
							setBillboardState(monster, "RETURNING")
							monster.humanoid:MoveTo(monster.standbyPos)
						end
					end

				------------------------------------------------------
				-- State: RETURNING (Walking back to standby post)
				------------------------------------------------------
				elseif monster.state == "RETURNING" then
					-- While returning, check if someone picked up a box!
					local interceptTarget = findBestCarrierTarget(monster)
					if interceptTarget and interceptTarget.Character then
						local hrp = interceptTarget.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if hrp then
							monster.state = "CHASING"
							monster.currentTarget = interceptTarget
							setBillboardState(monster, "CHASING", interceptTarget.Name)
							monster.humanoid:MoveTo(hrp.Position)
							notify:FireClient(interceptTarget, "🚨 " .. monster.name .. " intercepted and is chasing YOU!", "Warning")
						end
					else
						-- Continue walking back to standby post
						monster.humanoid:MoveTo(monster.standbyPos)

						local distToStandby = (monsterPos - monster.standbyPos).Magnitude
						if distToStandby <= 4.0 then
							-- Arrived back home!
							monster.state = "STANDBY"
							setBillboardState(monster, "STANDBY")
						else
							-- Anti-stuck watchdog: If returning and haven't moved for 5 seconds, nudge position
							if (monsterPos - monster.lastMovePos).Magnitude < 1.0 then
								monster.stuckTime += 0.3
								if monster.stuckTime > 5.0 then
									monster.primaryPart.CFrame = CFrame.new(monster.standbyPos + Vector3.new(0, 3, 0))
									monster.state = "STANDBY"
									setBillboardState(monster, "STANDBY")
									monster.stuckTime = 0
								end
							else
								monster.stuckTime = 0
								monster.lastMovePos = monsterPos
							end
						end
					end
				end
			end
		end
	end)

	-- 4. Clean up target reference if a player leaves
	Players.PlayerRemoving:Connect(function(player)
		MonsterService.OnBoxDropped(player)
	end)

	print("[MonsterService] Started with Safezone Barrier (R=" .. SAFEZONE_RADIUS .. ") and " .. #activeMonsters .. " Biome Guardian Monsters.")
end

return MonsterService
