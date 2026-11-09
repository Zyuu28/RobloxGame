--!strict
--[[
	SpeedService — Authoritative Walk Speed Management & Carry Slowdown.
	Authority: GDD §8.1, §9, §12.1 (AC-05, AC-11, AC-17).
	
	Features:
	  - Authoritative Humanoid WalkSpeed application across upgrades (16, 24, 35, 50).
	  - Dynamic carry slowdown: exactly 80% of current upgraded walk speed.
	  - Respawn and join preservation.
	  - Attribute replication: "CurrentWalkSpeed" and "WalkSpeedLevel".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UpgradesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("UpgradesConfig") :: ModuleScript)

local SpeedService = {}

local playerSpeedLevels: { [number]: number } = {}
local playerAccessoryBoosts: { [number]: number } = {}
local CarryService: any = nil

function SpeedService.Init()
	print("[SpeedService] Initialized.")
end

function SpeedService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	CarryService = require(servicesFolder:WaitForChild("CarryService") :: ModuleScript)

	local function hookCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			SpeedService.ApplySpeed(player)
		end
	end

	local function setupPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
		if player.Character then
			hookCharacter(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	print("[SpeedService] Started.")
end

function SpeedService.OnPlayerAdded(player: Player)
	playerSpeedLevels[player.UserId] = 0
	playerAccessoryBoosts[player.UserId] = 0
	player:SetAttribute("WalkSpeedLevel", 0)
	player:SetAttribute("EquippedSpeedBoost", 0)
	player:SetAttribute("CurrentWalkSpeed", 16)
end

function SpeedService.OnPlayerRemoving(player: Player)
	playerSpeedLevels[player.UserId] = nil
	playerAccessoryBoosts[player.UserId] = nil
end

function SpeedService.GetSpeedLevel(player: Player): number
	return playerSpeedLevels[player.UserId] or 0
end

function SpeedService.GetBaseSpeed(player: Player): number
	local level = SpeedService.GetSpeedLevel(player)
	local def = UpgradesConfig.WalkSpeed
	if def and def.levels[level + 1] then
		return def.levels[level + 1].newCapacity
	end
	return 16
end

function SpeedService.GetAccessorySpeedBoost(player: Player): number
	return playerAccessoryBoosts[player.UserId] or 0
end

function SpeedService.SetAccessorySpeedBoost(player: Player, boost: number)
	playerAccessoryBoosts[player.UserId] = boost
	player:SetAttribute("EquippedSpeedBoost", boost)
	SpeedService.ApplySpeed(player)
end

function SpeedService.GetTotalBaseSpeed(player: Player): number
	local base = SpeedService.GetBaseSpeed(player)
	local boost = SpeedService.GetAccessorySpeedBoost(player)
	return base + boost
end

function SpeedService.GetActualSpeed(player: Player): number
	local totalBase = SpeedService.GetTotalBaseSpeed(player)
	local isCarrying = CarryService and CarryService.IsCarrying(player)
	if isCarrying then
		-- Reduced to 80% of total walk speed when carrying (AC-05)
		return math.floor(totalBase * 0.80 * 10) / 10
	end
	return totalBase
end

function SpeedService.ApplySpeed(player: Player)
	local actualSpeed = SpeedService.GetActualSpeed(player)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = actualSpeed
		end
	end

	player:SetAttribute("CurrentWalkSpeed", actualSpeed)
	player:SetAttribute("WalkSpeedLevel", SpeedService.GetSpeedLevel(player))
	player:SetAttribute("EquippedSpeedBoost", SpeedService.GetAccessorySpeedBoost(player))
end

function SpeedService.SetSpeedLevel(player: Player, level: number)
	playerSpeedLevels[player.UserId] = level
	SpeedService.ApplySpeed(player)
end

return SpeedService
