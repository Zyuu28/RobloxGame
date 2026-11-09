--!strict
--[[
	InventoryController — Client-side inventory management and display placement actions.
	Authority: GDD §7.2, §12.1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local controllersFolder = script.Parent

local UIManager = require(controllersFolder:WaitForChild("UIManager") :: ModuleScript)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local CollectiblesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("CollectiblesConfig") :: ModuleScript)

local InventoryController = {}

-- Local inventory cache: [instanceId] = { itemId, obtainedAt, isDisplayed, standId }
local inventoryCache: { [string]: any } = {}
local currentCapacity = 20

local function refreshUI()
	local itemsList = {}
	for instanceId, itemData in pairs(inventoryCache) do
		local def = CollectiblesConfig[itemData.itemId]
		local name = if def then def.name else itemData.itemId
		local rarity = if def then def.rarity else "Common"
		local biomeId = if def then def.biomeId else "Urban"
		local income = if def then def.incomePerSecond else 2
		local speedBoost = if def then def.speedBoost else 2

		table.insert(itemsList, {
			instanceId = instanceId,
			itemId = itemData.itemId,
			name = name,
			biomeId = biomeId,
			rarity = rarity,
			incomePerSecond = income,
			speedBoost = speedBoost,
			isDisplayed = itemData.isDisplayed or false,
			isEquipped = itemData.isEquipped or false,
			standId = itemData.standId,
		})
	end

	-- Sort by rarity and name
	table.sort(itemsList, function(a, b)
		return a.name < b.name
	end)

	UIManager.PopulateInventory(itemsList, currentCapacity)
end

function InventoryController.Init()
	UIManager.OnInventoryToggle = function()
		UIManager.ToggleInventory()
	end

	UIManager.RefreshInventoryUI = function()
		refreshUI()
	end

	UIManager.OnItemActionClicked = function(instanceId: string, action: string)
		local item = inventoryCache[instanceId]
		if not item then return end

		if action == "Equip" then
			local equipEvent = Network.GetEvent(Network.Events.RequestEquip)
			equipEvent:FireServer(instanceId)
		elseif action == "Unequip" then
			local unequipEvent = Network.GetEvent(Network.Events.RequestUnequip)
			unequipEvent:FireServer(instanceId)
		elseif action == "Place" then
			-- Request placing on stand #1 (or next available stand)
			local displayEvent = Network.GetEvent(Network.Events.RequestDisplay)
			displayEvent:FireServer(instanceId, 1)
		elseif action == "Remove" then
			local standId = item.standId or 1
			local undisplayEvent = Network.GetEvent(Network.Events.RequestUndisplay)
			undisplayEvent:FireServer(standId)
		end
	end

	print("[InventoryController] Initialized.")
end

function InventoryController.Start()
	-- Listen for StateUpdate RemoteEvent for inventory changes
	local stateEvent = Network.GetEvent(Network.Events.StateUpdate)
	stateEvent.OnClientEvent:Connect(function(stateDelta)
		if stateDelta.inventory ~= nil then
			inventoryCache = stateDelta.inventory
			refreshUI()
		end
		if stateDelta.inventoryCapacity ~= nil then
			currentCapacity = stateDelta.inventoryCapacity
			refreshUI()
		end
	end)

	print("[InventoryController] Started.")
end

return InventoryController
