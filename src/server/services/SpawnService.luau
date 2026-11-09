--!strict
--[[
	SpawnService — Manages Mystery Box spawning, world instances, and pickup validation.
	Authority: Single Mystery Box per Biome & WorldMapV1.png.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local BoxesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("BoxesConfig") :: ModuleScript)

local SpawnService = {}

type WorldBoxRecord = {
	worldBoxId: string,
	boxTypeId: string,
	biomeId: string,
	part: Part,
	isAvailable: boolean,
	isDropped: boolean?,
}

local activeBoxes: { [string]: WorldBoxRecord } = {}
local CarryService: any = nil

local function getBiomesFolder(): Folder
	local world = Workspace:FindFirstChild("World")
	if not world then
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end

	local biomes = world:FindFirstChild("Biomes")
	if not biomes then
		biomes = Instance.new("Folder")
		biomes.Name = "Biomes"
		biomes.Parent = world
	end
	return biomes :: Folder
end

local function createRoad(name: string, fromPos: Vector3, toPos: Vector3, parent: Instance)
	local road = Instance.new("Part")
	road.Name = name
	local distance = (fromPos - toPos).Magnitude
	road.Size = Vector3.new(12, 0.8, distance)
	road.CFrame = CFrame.lookAt((fromPos + toPos) / 2, toPos)
	road.Anchored = true
	road.Material = Enum.Material.Concrete
	road.Color = Color3.fromRGB(55, 60, 75)
	road.TopSurface = Enum.SurfaceType.Smooth
	road.Parent = parent
end

local function createLockedPortal(name: string, pos: Vector3, title: string, color: Color3, parent: Instance)
	local gate = Instance.new("Model")
	gate.Name = name .. "_Gate"

	local pillar1 = Instance.new("Part")
	pillar1.Size = Vector3.new(3, 16, 3)
	pillar1.Position = pos + Vector3.new(-10, 8, 0)
	pillar1.Anchored = true
	pillar1.Color = Color3.fromRGB(40, 45, 60)
	pillar1.Parent = gate

	local pillar2 = Instance.new("Part")
	pillar2.Size = Vector3.new(3, 16, 3)
	pillar2.Position = pos + Vector3.new(10, 8, 0)
	pillar2.Anchored = true
	pillar2.Color = Color3.fromRGB(40, 45, 60)
	pillar2.Parent = gate

	local beam = Instance.new("Part")
	beam.Size = Vector3.new(23, 3, 3)
	beam.Position = pos + Vector3.new(0, 16, 0)
	beam.Anchored = true
	beam.Color = color
	beam.Material = Enum.Material.Neon
	beam.Parent = gate

	local barrier = Instance.new("Part")
	barrier.Size = Vector3.new(17, 13, 1)
	barrier.Position = pos + Vector3.new(0, 7.5, 0)
	barrier.Anchored = true
	barrier.Transparency = 0.5
	barrier.Color = color
	barrier.Material = Enum.Material.ForceField
	barrier.Parent = gate

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 50)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.Adornee = beam
	bb.Parent = beam

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	lbl.BackgroundTransparency = 0.2
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = color
	lbl.Text = title .. "\n[🔒 Locked - Phase 5]"
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = lbl
	lbl.Parent = bb

	gate.Parent = parent
end

local function setupBiomeZones(biomesFolder: Folder)
	-- 1. URBAN BIOME (North-West / Top-Left)
	local urbanFolder = biomesFolder:FindFirstChild("Urban")
	if not urbanFolder then
		urbanFolder = Instance.new("Folder")
		urbanFolder.Name = "Urban"
		urbanFolder.Parent = biomesFolder

		local urbanGround = Instance.new("Part")
		urbanGround.Name = "UrbanGround"
		urbanGround.Size = Vector3.new(160, 1, 160)
		urbanGround.Position = Vector3.new(-160, 0.5, 160)
		urbanGround.Anchored = true
		urbanGround.Material = Enum.Material.Concrete
		urbanGround.Color = Color3.fromRGB(48, 56, 70)
		urbanGround.TopSurface = Enum.SurfaceType.Smooth
		urbanGround.Parent = urbanFolder

		for b = 1, 3 do
			local bldg = Instance.new("Part")
			bldg.Name = "Building_" .. b
			bldg.Size = Vector3.new(24, 40 + b * 15, 24)
			bldg.Position = Vector3.new(-180 + (b - 1) * 35, 20 + b * 7.5, 180)
			bldg.Anchored = true
			bldg.Material = Enum.Material.SmoothPlastic
			bldg.Color = Color3.fromRGB(35, 42, 58)
			bldg.Parent = urbanFolder
		end

		createRoad("Road_Urban", Vector3.new(-45, 0.5, 45), Vector3.new(-115, 0.5, 115), urbanFolder)
	end

	-- 2. SLUMS BIOME (South-West / Bottom-Left)
	local slumsFolder = biomesFolder:FindFirstChild("Slums")
	if not slumsFolder then
		slumsFolder = Instance.new("Folder")
		slumsFolder.Name = "Slums"
		slumsFolder.Parent = biomesFolder

		local slumsGround = Instance.new("Part")
		slumsGround.Name = "SlumsGround"
		slumsGround.Size = Vector3.new(160, 1, 160)
		slumsGround.Position = Vector3.new(-160, 0.5, -160)
		slumsGround.Anchored = true
		slumsGround.Material = Enum.Material.CorrodedMetal
		slumsGround.Color = Color3.fromRGB(75, 55, 42)
		slumsGround.TopSurface = Enum.SurfaceType.Smooth
		slumsGround.Parent = slumsFolder

		for s = 1, 3 do
			local scrap = Instance.new("Part")
			scrap.Name = "ScrapHeap_" .. s
			scrap.Size = Vector3.new(18, 12, 18)
			scrap.Position = Vector3.new(-180 + (s - 1) * 30, 6, -180 + (s % 2) * 25)
			scrap.Anchored = true
			scrap.Material = Enum.Material.Rust
			scrap.Color = Color3.fromRGB(110, 70, 50)
			scrap.Parent = slumsFolder
		end

		createRoad("Road_Slums", Vector3.new(-45, 0.5, -45), Vector3.new(-115, 0.5, -115), slumsFolder)
	end

	-- 3. MOUNTAIN BIOME (North / Top-Center) [Post-MVP]
	local mountainFolder = biomesFolder:FindFirstChild("Mountain")
	if not mountainFolder then
		mountainFolder = Instance.new("Folder")
		mountainFolder.Name = "Mountain"
		mountainFolder.Parent = biomesFolder

		local mtnGround = Instance.new("Part")
		mtnGround.Name = "MountainGround"
		mtnGround.Size = Vector3.new(140, 1, 120)
		mtnGround.Position = Vector3.new(0, 0.5, 210)
		mtnGround.Anchored = true
		mtnGround.Material = Enum.Material.Slate
		mtnGround.Color = Color3.fromRGB(38, 70, 48)
		mtnGround.Parent = mountainFolder

		createRoad("Road_Mountain", Vector3.new(0, 0.5, 55), Vector3.new(0, 0.5, 145), mountainFolder)
		createLockedPortal("Mountain", Vector3.new(0, 0.5, 148), "🏔️ MOUNTAIN BIOME", Color3.fromRGB(76, 175, 80), mountainFolder)
	end

	-- 4. SPACE BIOME (North-East / Top-Right) [Post-MVP]
	local spaceFolder = biomesFolder:FindFirstChild("Space")
	if not spaceFolder then
		spaceFolder = Instance.new("Folder")
		spaceFolder.Name = "Space"
		spaceFolder.Parent = biomesFolder

		local spaceGround = Instance.new("Part")
		spaceGround.Name = "SpaceGround"
		spaceGround.Size = Vector3.new(160, 1, 160)
		spaceGround.Position = Vector3.new(160, 0.5, 160)
		spaceGround.Anchored = true
		spaceGround.Material = Enum.Material.SmoothPlastic
		spaceGround.Color = Color3.fromRGB(28, 20, 45)
		spaceGround.Parent = spaceFolder

		createRoad("Road_Space", Vector3.new(45, 0.5, 45), Vector3.new(115, 0.5, 115), spaceFolder)
		createLockedPortal("Space", Vector3.new(115, 0.5, 115), "🚀 SPACE BIOME", Color3.fromRGB(170, 80, 255), spaceFolder)
	end

	-- 5. OCEAN BIOME (South-East / Bottom-Right) [Post-MVP]
	local oceanFolder = biomesFolder:FindFirstChild("Ocean")
	if not oceanFolder then
		oceanFolder = Instance.new("Folder")
		oceanFolder.Name = "Ocean"
		oceanFolder.Parent = biomesFolder

		local oceanGround = Instance.new("Part")
		oceanGround.Name = "OceanGround"
		oceanGround.Size = Vector3.new(160, 1, 160)
		oceanGround.Position = Vector3.new(160, 0.5, -160)
		oceanGround.Anchored = true
		oceanGround.Material = Enum.Material.Glass
		oceanGround.Color = Color3.fromRGB(15, 65, 95)
		oceanGround.Parent = oceanFolder

		createRoad("Road_Ocean", Vector3.new(45, 0.5, -45), Vector3.new(115, 0.5, -115), oceanFolder)
		createLockedPortal("Ocean", Vector3.new(115, 0.5, -115), "🌊 OCEAN BIOME", Color3.fromRGB(0, 200, 240), oceanFolder)
	end
end

--[[
	Spawns the Biome Mystery Box in the world.
	Each biome has exactly ONE Mystery Box type.
]]
local function spawnBoxInstance(worldBoxId: string, biomeId: string, position: Vector3): Part
	local biomesFolder = getBiomesFolder()
	local biomeFolder = biomesFolder:FindFirstChild(biomeId) or biomesFolder

	local boxTypeId = biomeId .. "_Box"
	local boxDef = BoxesConfig.GetBox(boxTypeId)
	local boxName = if boxDef then boxDef.displayName else (biomeId .. " Mystery Box")
	local boxColor = if boxDef then boxDef.themeColor else Color3.fromRGB(0, 190, 255)

	local boxPart = Instance.new("Part")
	boxPart.Name = "Box_" .. worldBoxId
	boxPart.Size = Vector3.new(3, 3, 3)
	boxPart.Position = position + Vector3.new(0, 1.5, 0)
	boxPart.Anchored = true
	boxPart.CanCollide = true
	boxPart.Material = Enum.Material.Neon
	boxPart.Color = boxColor
	boxPart:SetAttribute("WorldBoxId", worldBoxId)
	boxPart:SetAttribute("BiomeId", biomeId)
	boxPart:SetAttribute("BoxTypeId", boxTypeId)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BoxBillboard"
	billboard.Size = UDim2.new(0, 180, 0, 48)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.Adornee = boxPart
	billboard.Parent = boxPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	label.BackgroundTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = boxColor
	label.Text = boxName .. "\n[Hold F to Pick Up]"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = boxName .. " [F]"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("PromptType", "PickupBox")
	prompt.Parent = boxPart

	boxPart.Parent = biomeFolder
	return boxPart
end

function SpawnService.Init()
	local biomesFolder = getBiomesFolder()
	setupBiomeZones(biomesFolder)

	-- Spawn Mystery Boxes:
	-- Urban has Urban Mystery Boxes
	-- Slums has Slums Mystery Boxes
	local sampleBoxes = {
		{ id = "Urban_Box_1", biome = "Urban", pos = Vector3.new(-140, 0.5, 140) },
		{ id = "Urban_Box_2", biome = "Urban", pos = Vector3.new(-165, 0.5, 175) },
		{ id = "Urban_Box_3", biome = "Urban", pos = Vector3.new(-180, 0.5, 145) },
		{ id = "Urban_Box_4", biome = "Urban", pos = Vector3.new(-195, 0.5, 190) },
		{ id = "Slums_Box_1", biome = "Slums", pos = Vector3.new(-140, 0.5, -140) },
		{ id = "Slums_Box_2", biome = "Slums", pos = Vector3.new(-170, 0.5, -165) },
		{ id = "Slums_Box_3", biome = "Slums", pos = Vector3.new(-190, 0.5, -185) },
	}

	for _, item in ipairs(sampleBoxes) do
		local part = spawnBoxInstance(item.id, item.biome, item.pos)
		activeBoxes[item.id] = {
			worldBoxId = item.id,
			boxTypeId = item.biome .. "_Box",
			biomeId = item.biome,
			part = part,
			isAvailable = true,
		}
	end

	print("[SpawnService] Initialized " .. #sampleBoxes .. " Biome Mystery Boxes.")
end

local droppedCount = 0

--- Spawns a dropped mystery box in the world with a ProximityPrompt so any player can pick it up again.
function SpawnService.SpawnDroppedBox(boxTypeId: string, biomeId: string, position: Vector3): Part
	droppedCount += 1
	local dropId = "Dropped_" .. tostring(os.clock()) .. "_" .. droppedCount

	local biomesFolder = getBiomesFolder()
	local biomeFolder = biomesFolder:FindFirstChild(biomeId) or biomesFolder

	local boxDef = BoxesConfig.GetBox(boxTypeId)
	local boxName = if boxDef then boxDef.displayName else (biomeId .. " Mystery Box")
	local boxColor = if boxDef then boxDef.themeColor else Color3.fromRGB(0, 190, 255)

	local boxPart = Instance.new("Part")
	boxPart.Name = "DroppedBox_" .. dropId
	boxPart.Size = Vector3.new(2.8, 2.8, 2.8)
	boxPart.Position = position + Vector3.new(0, 1.4, 0)
	boxPart.Anchored = true
	boxPart.CanCollide = true
	boxPart.Material = Enum.Material.Neon
	boxPart.Color = boxColor
	boxPart:SetAttribute("WorldBoxId", dropId)
	boxPart:SetAttribute("BiomeId", biomeId)
	boxPart:SetAttribute("BoxTypeId", boxTypeId)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BoxBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 48)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.Adornee = boxPart
	billboard.Parent = boxPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	label.BackgroundTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = boxColor
	label.Text = "📦 DROPPED " .. boxName .. "\n[Hold F to Pick Up]"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = boxName .. " (Dropped) [F]"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("PromptType", "PickupBox")
	prompt:SetAttribute("WorldBoxId", dropId)
	prompt.Parent = boxPart

	boxPart.Parent = biomeFolder

	activeBoxes[dropId] = {
		worldBoxId = dropId,
		boxTypeId = boxTypeId,
		biomeId = biomeId,
		part = boxPart,
		isAvailable = true,
		isDropped = true,
	}

	-- Auto-despawn after 60 seconds if not picked up
	task.delay(60, function()
		local rec = activeBoxes[dropId]
		if rec and rec.isAvailable and rec.part and rec.part.Parent then
			rec.part:Destroy()
			activeBoxes[dropId] = nil
		end
	end)

	print("[SpawnService] Spawned dropped box: " .. dropId .. " (" .. biomeId .. ") at " .. tostring(position))
	return boxPart
end

function SpawnService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	CarryService = require(servicesFolder:WaitForChild("CarryService") :: ModuleScript)

	local pickupEvent = Network.GetEvent(Network.Events.RequestPickup)
	pickupEvent.OnServerEvent:Connect(function(player: Player, worldBoxId: string)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)

		-- 1. Check if player already carrying a box
		if CarryService.IsCarrying(player) then
			notify:FireClient(player, "You can only carry ONE box at a time!", "Warning")
			return
		end

		-- 2. Check if box exists and is available
		local boxRecord = activeBoxes[worldBoxId]
		if not boxRecord or not boxRecord.isAvailable then
			notify:FireClient(player, "This box was already taken!", "Error")
			return
		end

		-- 3. Distance check (server validation)
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp or (hrp.Position - boxRecord.part.Position).Magnitude > 16 then
			notify:FireClient(player, "You are too far from the box!", "Error")
			return
		end

		-- 4. Atomically claim
		boxRecord.isAvailable = false
		local boxPos = boxRecord.part.Position
		local biome = boxRecord.biomeId
		local boxTypeId = boxRecord.boxTypeId
		local isDropped = boxRecord.isDropped == true
		boxRecord.part:Destroy()

		if isDropped then
			activeBoxes[worldBoxId] = nil
		end

		CarryService.SetCarriedBox(player, boxTypeId, biome)
		notify:FireClient(player, "Picked up " .. biome .. " Mystery Box! Carry it back to your plot to open.", "Success")

		-- Respawn after cooldown ONLY if it was a fixed world box (not a dropped box)
		if not isDropped then
			task.delay(math.random(25, 40), function()
				local newPart = spawnBoxInstance(worldBoxId, biome, boxPos - Vector3.new(0, 1.5, 0))
				activeBoxes[worldBoxId] = {
					worldBoxId = worldBoxId,
					boxTypeId = boxTypeId,
					biomeId = biome,
					part = newPart,
					isAvailable = true,
					isDropped = false,
				}
			end)
		end
	end)

	print("[SpawnService] Started.")
end

return SpawnService
