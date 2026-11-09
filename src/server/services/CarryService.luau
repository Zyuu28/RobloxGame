--!strict
--[[
	CarryService — Manages Mystery Box pickup, visual attachment, carry state, and DROP.
	Authority: GDD §5.1 — Single Mystery Box per player, carry slowdown, drop support.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BoxesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("BoxesConfig") :: ModuleScript)

local CarryService = {}

export type CarriedBoxInfo = {
	boxTypeId: string,
	biomeId: string,
	visualPart: Part?,
}

local carriedBoxes: { [number]: CarriedBoxInfo } = {}
local SpeedService: any = nil
local MonsterService: any = nil
local SpawnService: any = nil

local function attachBoxToCharacter(character: Model, boxTypeId: string, biomeId: string): Part?
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end

	local boxDef = BoxesConfig.GetBox(boxTypeId)
	local boxColor = if boxDef then boxDef.themeColor else Color3.fromRGB(0, 190, 255)

	local boxPart = Instance.new("Part")
	boxPart.Name = "CarriedMysteryBox"
	boxPart.Size = Vector3.new(2.4, 2.4, 2.4)
	boxPart.CanCollide = false
	boxPart.Massless = true
	boxPart.Material = Enum.Material.Neon
	boxPart.Color = boxColor

	-- Weld to HumanoidRootPart in front of avatar
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = boxPart
	weld.C0 = CFrame.new(0, 0.5, -2)
	weld.Parent = boxPart

	boxPart.Parent = character
	return boxPart
end

local function hookCharacterDied(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(function()
			if CarryService.IsCarrying(player) then
				CarryService.DropBox(player)
			else
				CarryService.ClearCarriedBox(player)
			end
		end)
	end
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		hookCharacterDied(player, character)
	end)
	if player.Character then
		hookCharacterDied(player, player.Character)
	end
end

function CarryService.Init()
	print("[CarryService] Initialized.")
end

function CarryService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	SpeedService = require(servicesFolder:WaitForChild("SpeedService") :: ModuleScript)
	MonsterService = require(servicesFolder:WaitForChild("MonsterService") :: ModuleScript)
	SpawnService = require(servicesFolder:WaitForChild("SpawnService") :: ModuleScript)

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	print("[CarryService] Started.")
end

function CarryService.OnPlayerRemoving(player: Player)
	if CarryService.IsCarrying(player) then
		CarryService.DropBox(player)
	else
		CarryService.ClearCarriedBox(player)
	end
end

function CarryService.IsCarrying(player: Player): boolean
	return carriedBoxes[player.UserId] ~= nil
end

function CarryService.GetCarriedBox(player: Player): CarriedBoxInfo?
	return carriedBoxes[player.UserId]
end

function CarryService.SetCarriedBox(player: Player, boxTypeId: string, biomeId: string): boolean
	if CarryService.IsCarrying(player) then
		return false
	end

	local char = player.Character
	local visualPart: Part? = nil
	if char then
		visualPart = attachBoxToCharacter(char, boxTypeId, biomeId)
	end

	carriedBoxes[player.UserId] = {
		boxTypeId = boxTypeId,
		biomeId = biomeId,
		visualPart = visualPart,
	}

	player:SetAttribute("CarryingBox", boxTypeId)

	-- Apply authoritative carry slowdown (80% of current upgraded walk speed)
	if SpeedService then
		SpeedService.ApplySpeed(player)
	end

	-- Notify MonsterService that this player picked up a mystery box!
	if MonsterService then
		if MonsterService.OnBoxPickedUp then
			MonsterService.OnBoxPickedUp(player, biomeId)
		elseif MonsterService.SpawnChaseMonster then
			MonsterService.SpawnChaseMonster(player, biomeId)
		end
	end

	return true
end

function CarryService.ClearCarriedBox(player: Player)
	local carried = carriedBoxes[player.UserId]
	if carried then
		if carried.visualPart and carried.visualPart.Parent then
			carried.visualPart:Destroy()
		end
		carriedBoxes[player.UserId] = nil
	end

	player:SetAttribute("CarryingBox", nil)

	-- Restore authoritative full upgraded walk speed
	if SpeedService then
		SpeedService.ApplySpeed(player)
	end

	-- Notify MonsterService that carried box was cleared/dropped
	if MonsterService then
		if MonsterService.OnBoxDropped then
			MonsterService.OnBoxDropped(player)
		elseif MonsterService.DespawnMonster then
			MonsterService.DespawnMonster(player)
		end
	end
end

--- DropBox — Player drops the carried mystery box on the ground.
--- Creates a real interactive dropped box with ProximityPrompt so ANY player can pick it up again!
function CarryService.DropBox(player: Player): boolean
	if not CarryService.IsCarrying(player) then
		return false
	end

	local carried = carriedBoxes[player.UserId]
	if not carried then return false end

	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local dropPos = if hrp then hrp.Position - Vector3.new(0, 1.2, 0) else Vector3.new(0, 1, 0)

	local boxTypeId = carried.boxTypeId
	local biomeId = carried.biomeId

	-- 1. Clear carry state (removes attached visual part, resets speed, notifies monster)
	CarryService.ClearCarriedBox(player)

	-- 2. Spawn real dropped box in the world with ProximityPrompt so anyone can pick it back up!
	if SpawnService and SpawnService.SpawnDroppedBox then
		SpawnService.SpawnDroppedBox(boxTypeId, biomeId, dropPos)
	end

	return true
end

return CarryService
