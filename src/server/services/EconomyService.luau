--!strict
--[[
	EconomyService — Manages currency, passive income ticks, claims, and upgrades.
	Authority: GDD §8, §8.1.
	
	Server-authoritative: no client-side currency manipulation.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local EconomyConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("EconomyConfig") :: ModuleScript)
local UpgradesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("UpgradesConfig") :: ModuleScript)

local EconomyService = {}

export type PlayerEconomyState = {
	bucks: number,
	pendingBucks: number,
	inventoryCapacityLevel: number,
	displayCapacityLevel: number,
	walkSpeedLevel: number,
}

local playerStates: { [number]: PlayerEconomyState } = {}
local DisplayService: any = nil
local PlotService: any = nil
local SpeedService: any = nil

function EconomyService.Init()
	print("[EconomyService] Initialized.")
end

function EconomyService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	DisplayService = require(servicesFolder:WaitForChild("DisplayService") :: ModuleScript)
	PlotService = require(servicesFolder:WaitForChild("PlotService") :: ModuleScript)
	SpeedService = require(servicesFolder:WaitForChild("SpeedService") :: ModuleScript)

	-- Handle RequestClaim
	local claimEvent = Network.GetEvent(Network.Events.RequestClaim)
	claimEvent.OnServerEvent:Connect(function(player: Player, plotId: string)
		if not PlotService.IsPlotOwner(player, plotId) then
			local notify = Network.GetEvent(Network.Events.NotifyFeedback)
			notify:FireClient(player, "You can only claim from your own plot!", "Error")
			return
		end

		local state = playerStates[player.UserId]
		if not state then return end

		if state.pendingBucks <= 0 then
			local notify = Network.GetEvent(Network.Events.NotifyFeedback)
			notify:FireClient(player, "No pending Bucks to claim yet!", "Warning")
			return
		end

		local claimed = state.pendingBucks
		state.bucks += claimed
		state.pendingBucks = 0

		EconomyService.ReplicateState(player)

		local notify = Network.GetEvent(Network.Events.NotifyFeedback)
		notify:FireClient(player, "Claimed $" .. tostring(claimed) .. " Bucks!", "Success")
	end)

	-- Handle RequestUpgrade
	local upgradeEvent = Network.GetEvent(Network.Events.RequestUpgrade)
	upgradeEvent.OnServerEvent:Connect(function(player: Player, upgradeId: string)
		local state = playerStates[player.UserId]
		if not state then return end

		local notify = Network.GetEvent(Network.Events.NotifyFeedback)

		if upgradeId == "InventoryCapacity" then
			local def = UpgradesConfig.InventoryCapacity
			if state.inventoryCapacityLevel >= def.maxLevel then
				notify:FireClient(player, "Inventory Capacity is already at MAX level!", "Warning")
				return
			end
			local nextLevelInfo = def.levels[state.inventoryCapacityLevel + 2]
			if state.bucks < nextLevelInfo.costBucks then
				notify:FireClient(player, "Not enough Bucks! Need $" .. nextLevelInfo.costBucks, "Error")
				return
			end

			state.bucks -= nextLevelInfo.costBucks
			state.inventoryCapacityLevel += 1
			EconomyService.ReplicateState(player)
			notify:FireClient(player, "Upgraded Inventory to " .. nextLevelInfo.newCapacity .. " slots!", "Success")

		elseif upgradeId == "DisplayStandCapacity" then
			local def = UpgradesConfig.DisplayStandCapacity
			if state.displayCapacityLevel >= def.maxLevel then
				notify:FireClient(player, "Display Stand Capacity is already at MAX level!", "Warning")
				return
			end
			local nextLevelInfo = def.levels[state.displayCapacityLevel + 2]
			if state.bucks < nextLevelInfo.costBucks then
				notify:FireClient(player, "Not enough Bucks! Need $" .. nextLevelInfo.costBucks, "Error")
				return
			end

			state.bucks -= nextLevelInfo.costBucks
			state.displayCapacityLevel += 1
			EconomyService.ReplicateState(player)
			notify:FireClient(player, "Upgraded Display Stands to " .. nextLevelInfo.newCapacity .. " stands!", "Success")

		elseif upgradeId == "WalkSpeed" then
			local def = UpgradesConfig.WalkSpeed
			if state.walkSpeedLevel >= def.maxLevel then
				notify:FireClient(player, "Walk Speed is already at MAX level!", "Warning")
				return
			end
			local nextLevelInfo = def.levels[state.walkSpeedLevel + 2]
			if state.bucks < nextLevelInfo.costBucks then
				notify:FireClient(player, "Not enough Bucks! Need $" .. nextLevelInfo.costBucks, "Error")
				return
			end

			state.bucks -= nextLevelInfo.costBucks
			state.walkSpeedLevel += 1
			if SpeedService then
				SpeedService.SetSpeedLevel(player, state.walkSpeedLevel)
			end
			EconomyService.ReplicateState(player)
			notify:FireClient(player, "Upgraded Walk Speed to " .. nextLevelInfo.newCapacity .. " studs/s!", "Success")
		end
	end)

	-- Economy passive income tick loop (1 second interval)
	task.spawn(function()
		while true do
			task.wait(EconomyConfig.economyTickInterval or 1)
			for _, player in Players:GetPlayers() do
				local state = playerStates[player.UserId]
				if state then
					local incomeRate = 0
					if DisplayService and DisplayService.GetPlayerIncomeRate then
						incomeRate = DisplayService.GetPlayerIncomeRate(player)
					end

					if incomeRate > 0 then
						state.pendingBucks += incomeRate
						EconomyService.ReplicateState(player)
					end
				end
			end
		end
	end)

	print("[EconomyService] Started.")
end

function EconomyService.OnPlayerAdded(player: Player)
	playerStates[player.UserId] = {
		bucks = EconomyConfig.baseBucks or 0,
		pendingBucks = 0,
		inventoryCapacityLevel = 0,
		displayCapacityLevel = 0,
		walkSpeedLevel = 0,
	}
	EconomyService.ReplicateState(player)
end

function EconomyService.OnPlayerRemoving(player: Player)
	playerStates[player.UserId] = nil
end

function EconomyService.GetBucks(player: Player): number
	local state = playerStates[player.UserId]
	return if state then state.bucks else 0
end

function EconomyService.GetInventoryCapacity(player: Player): number
	local state = playerStates[player.UserId]
	local level = if state then state.inventoryCapacityLevel else 0
	local def = UpgradesConfig.InventoryCapacity
	return def.levels[level + 1].newCapacity
end

function EconomyService.GetDisplayCapacity(player: Player): number
	local state = playerStates[player.UserId]
	local level = if state then state.displayCapacityLevel else 0
	local def = UpgradesConfig.DisplayStandCapacity
	return def.levels[level + 1].newCapacity
end

function EconomyService.GetWalkSpeed(player: Player): number
	local state = playerStates[player.UserId]
	local level = if state then state.walkSpeedLevel else 0
	local def = UpgradesConfig.WalkSpeed
	return def.levels[level + 1].newCapacity
end

function EconomyService.ReplicateState(player: Player)
	local state = playerStates[player.UserId]
	if not state then return end

	local incomeRate = 0
	if DisplayService and DisplayService.GetPlayerIncomeRate then
		incomeRate = DisplayService.GetPlayerIncomeRate(player)
	end

	local baseSpeed = if SpeedService then SpeedService.GetBaseSpeed(player) else 16
	local actualSpeed = if SpeedService then SpeedService.GetActualSpeed(player) else 16

	local stateEvent = Network.GetEvent(Network.Events.StateUpdate)
	stateEvent:FireClient(player, {
		bucks = state.bucks,
		pendingBucks = state.pendingBucks,
		incomeRate = incomeRate,
		inventoryCapacityLevel = state.inventoryCapacityLevel,
		displayCapacityLevel = state.displayCapacityLevel,
		walkSpeedLevel = state.walkSpeedLevel,
		inventoryCapacity = EconomyService.GetInventoryCapacity(player),
		displayCapacity = EconomyService.GetDisplayCapacity(player),
		walkSpeed = baseSpeed,
		actualWalkSpeed = actualSpeed,
	})
end

return EconomyService
