--!strict
--[[
	InventoryService — Manages player collectible inventory instances, capacity,
	and Wearable Accessories with Speed Boost integration.
	Authority: GDD §7.2, §6, & Equippable Speed Accessories.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local EconomyConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("EconomyConfig") :: ModuleScript)
local CollectiblesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("CollectiblesConfig") :: ModuleScript)

local InventoryService = {}

export type CollectibleInstance = {
	instanceId: string,
	itemId: string,
	obtainedAt: number,
	isDisplayed: boolean,
	standId: number?,
	isEquipped: boolean?,
}

local playerInventories: { [number]: { [string]: CollectibleInstance } } = {}
local playerEquippedInstance: { [number]: string? } = {}
local playerEquippedModels: { [number]: Model? } = {}

local EconomyService: any = nil
local SpeedService: any = nil

local function clearEquippedVisual(player: Player)
	local existing = playerEquippedModels[player.UserId]
	if existing and existing.Parent then
		existing:Destroy()
	end
	playerEquippedModels[player.UserId] = nil
end

local function attachVisualAccessory(player: Player, itemId: string): Model?
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end

	clearEquippedVisual(player)

	local def = CollectiblesConfig[itemId]
	local rarityColor = Color3.fromRGB(0, 200, 255)
	if def then
		if def.rarity == "Common" then rarityColor = Color3.fromRGB(180, 180, 180)
		elseif def.rarity == "Uncommon" then rarityColor = Color3.fromRGB(76, 175, 80)
		elseif def.rarity == "Rare" then rarityColor = Color3.fromRGB(33, 150, 243)
		elseif def.rarity == "Epic" then rarityColor = Color3.fromRGB(156, 39, 176)
		elseif def.rarity == "Legendary" then rarityColor = Color3.fromRGB(255, 193, 7)
		elseif def.rarity == "Secret" then rarityColor = Color3.fromRGB(255, 23, 68)
		end
	end

	local model = Instance.new("Model")
	model.Name = "EquippedAccessory_" .. player.Name

	-- Floating companion orb / tech device hovering near avatar's shoulder
	local prop = Instance.new("Part")
	prop.Name = "AccessoryProp"
	prop.Size = Vector3.new(1.2, 1.2, 1.2)
	prop.Material = Enum.Material.Neon
	prop.Color = rarityColor
	prop.CanCollide = false
	prop.Massless = true
	prop.Parent = model

	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = prop
	weld.C0 = CFrame.new(1.8, 1.6, 0.8)
	weld.Parent = prop

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 32)
	billboard.StudsOffset = Vector3.new(0, 1.2, 0)
	billboard.Adornee = prop
	billboard.Parent = prop

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextColor3 = rarityColor
	label.Text = if def then ("⚡ " .. def.name .. " (+" .. tostring(def.speedBoost) .. ")") else "⚡ Accessory"
	label.Parent = billboard

	model.PrimaryPart = prop
	model.Parent = char
	playerEquippedModels[player.UserId] = model
	return model
end

function InventoryService.Init()
	print("[InventoryService] Initialized.")
end

function InventoryService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	EconomyService = require(servicesFolder:WaitForChild("EconomyService") :: ModuleScript)
	SpeedService = require(servicesFolder:WaitForChild("SpeedService") :: ModuleScript)

	-- Handle RequestEquip
	local equipEvent = Network.GetEvent(Network.Events.RequestEquip)
	equipEvent.OnServerEvent:Connect(function(player: Player, instanceId: string)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)
		local inv = playerInventories[player.UserId]
		if not inv then return end

		local item = inv[instanceId]
		if not item then
			notify:FireClient(player, "Item not found in inventory!", "Error")
			return
		end

		local def = CollectiblesConfig[item.itemId]
		if not def or not def.wearable then
			notify:FireClient(player, "This item cannot be equipped!", "Warning")
			return
		end

		-- Unequip previously equipped item if any
		for otherId, otherItem in pairs(inv) do
			if otherItem.isEquipped and otherId ~= instanceId then
				otherItem.isEquipped = false
			end
		end

		item.isEquipped = true
		playerEquippedInstance[player.UserId] = instanceId

		attachVisualAccessory(player, item.itemId)

		if SpeedService then
			SpeedService.SetAccessorySpeedBoost(player, def.speedBoost)
		end

		InventoryService.ReplicateInventory(player)
		notify:FireClient(player, "⚡ Equipped " .. def.name .. "! (+" .. tostring(def.speedBoost) .. " Speed Boost)", "Success")
	end)

	-- Handle RequestUnequip
	local unequipEvent = Network.GetEvent(Network.Events.RequestUnequip)
	unequipEvent.OnServerEvent:Connect(function(player: Player, instanceId: string)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)
		local inv = playerInventories[player.UserId]
		if not inv then return end

		local item = inv[instanceId]
		if not item then return end

		item.isEquipped = false
		playerEquippedInstance[player.UserId] = nil
		clearEquippedVisual(player)

		if SpeedService then
			SpeedService.SetAccessorySpeedBoost(player, 0)
		end

		InventoryService.ReplicateInventory(player)
		notify:FireClient(player, "Unequipped accessory.", "Warning")
	end)

	-- Hook character respawn to re-attach equipped visual
	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			local eqId = playerEquippedInstance[player.UserId]
			if eqId then
				local inv = playerInventories[player.UserId]
				local item = inv and inv[eqId]
				if item and item.isEquipped then
					attachVisualAccessory(player, item.itemId)
					local def = CollectiblesConfig[item.itemId]
					if def and SpeedService then
						SpeedService.SetAccessorySpeedBoost(player, def.speedBoost)
					end
				end
			end
		end)
	end

	Players.PlayerAdded:Connect(hookPlayer)
	for _, p in Players:GetPlayers() do
		hookPlayer(p)
	end

	print("[InventoryService] Started with Equippable Speed Accessories.")
end

function InventoryService.OnPlayerAdded(player: Player)
	playerInventories[player.UserId] = {}
	playerEquippedInstance[player.UserId] = nil
	InventoryService.ReplicateInventory(player)
end

function InventoryService.OnPlayerRemoving(player: Player)
	clearEquippedVisual(player)
	playerInventories[player.UserId] = nil
	playerEquippedInstance[player.UserId] = nil
end

function InventoryService.GetInventoryCount(player: Player): number
	local inv = playerInventories[player.UserId]
	if not inv then return 0 end

	local count = 0
	for _, item in pairs(inv) do
		if not EconomyConfig.displayedCountsAsInventory and item.isDisplayed then
			continue
		end
		count += 1
	end
	return count
end

function InventoryService.IsFull(player: Player): boolean
	local maxCap = 20
	if EconomyService and EconomyService.GetInventoryCapacity then
		maxCap = EconomyService.GetInventoryCapacity(player)
	end
	return InventoryService.GetInventoryCount(player) >= maxCap
end

function InventoryService.AddItem(player: Player, itemId: string): (boolean, string?)
	if InventoryService.IsFull(player) then
		return false, nil
	end

	local inv = playerInventories[player.UserId]
	if not inv then
		inv = {}
		playerInventories[player.UserId] = inv
	end

	local instanceId = HttpService:GenerateGUID(false)
	local itemInstance: CollectibleInstance = {
		instanceId = instanceId,
		itemId = itemId,
		obtainedAt = os.time(),
		isDisplayed = false,
		standId = nil,
		isEquipped = false,
	}

	inv[instanceId] = itemInstance
	InventoryService.ReplicateInventory(player)
	return true, instanceId
end

function InventoryService.GetItem(player: Player, instanceId: string): CollectibleInstance?
	local inv = playerInventories[player.UserId]
	if not inv then return nil end
	return inv[instanceId]
end

function InventoryService.SetItemDisplayed(player: Player, instanceId: string, isDisplayed: boolean, standId: number?)
	local inv = playerInventories[player.UserId]
	if not inv then return end

	local item = inv[instanceId]
	if item then
		item.isDisplayed = isDisplayed
		item.standId = if isDisplayed then standId else nil
		InventoryService.ReplicateInventory(player)
	end
end

function InventoryService.ReplicateInventory(player: Player)
	local inv = playerInventories[player.UserId] or {}
	local maxCap = 20
	if EconomyService and EconomyService.GetInventoryCapacity then
		maxCap = EconomyService.GetInventoryCapacity(player)
	end

	local stateEvent = Network.GetEvent(Network.Events.StateUpdate)
	stateEvent:FireClient(player, {
		inventory = inv,
		inventoryCapacity = maxCap,
		equippedInstanceId = playerEquippedInstance[player.UserId],
	})
end

return InventoryService
