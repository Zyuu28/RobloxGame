--!strict
--[[
	DisplayService — Manages display stands, placed collectibles, and passive income contribution.
	Authority: GDD §7.2, §4, §8.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local CollectiblesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("CollectiblesConfig") :: ModuleScript)

local DisplayService = {}

-- plotStands[plotId] = { [standId: number] = instanceId: string }
local plotStands: { [string]: { [number]: string } } = {}

local PlotService: any = nil
local InventoryService: any = nil
local EconomyService: any = nil

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(76, 175, 80),
	Rare      = Color3.fromRGB(33, 150, 243),
	Epic      = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7),
	Secret    = Color3.fromRGB(255, 23, 68),
}

local function updatePhysicalStand(plotId: string, standId: number, itemName: string?, rarity: string?, income: number?)
	local world = Workspace:FindFirstChild("World")
	if not world then return end
	local plotsFolder = world:FindFirstChild("PlayerPlots")
	if not plotsFolder then return end
	local plotModel = plotsFolder:FindFirstChild(plotId)
	if not plotModel then return end
	local stand = plotModel:FindFirstChild("Stand_" .. tostring(standId)) :: BasePart?
	if not stand then return end

	-- Clear old preview model
	local oldPreview = stand:FindFirstChild("PreviewModel")
	if oldPreview then
		oldPreview:Destroy()
	end

	local billboard = stand:FindFirstChild("StandBillboard")
	local label = if billboard then billboard:FindFirstChild("StandLabel") :: TextLabel? else nil

	if itemName and rarity and income then
		-- Spawn decorative display cube
		local preview = Instance.new("Part")
		preview.Name = "PreviewModel"
		preview.Size = Vector3.new(2, 2, 2)
		preview.Position = stand.Position + Vector3.new(0, 2.5, 0)
		preview.Anchored = true
		preview.Material = Enum.Material.Neon
		preview.Color = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
		preview.Parent = stand

		if label then
			label.Text = itemName .. "\n(+$" .. tostring(income) .. "/s)"
			label.TextColor3 = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
		end
	else
		if label then
			label.Text = "Stand #" .. standId .. "\n(Empty)"
			label.TextColor3 = Color3.fromRGB(200, 210, 230)
		end
	end
end

function DisplayService.Init()
	print("[DisplayService] Initialized.")
end

function DisplayService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	PlotService = require(servicesFolder:WaitForChild("PlotService") :: ModuleScript)
	InventoryService = require(servicesFolder:WaitForChild("InventoryService") :: ModuleScript)
	EconomyService = require(servicesFolder:WaitForChild("EconomyService") :: ModuleScript)

	-- Handle RequestDisplay
	local displayEvent = Network.GetEvent(Network.Events.RequestDisplay)
	displayEvent.OnServerEvent:Connect(function(player: Player, instanceId: string, requestedStandId: number?)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)
		local plotId = PlotService.GetPlotForPlayer(player)
		if not plotId then
			notify:FireClient(player, "You don't have an assigned plot!", "Error")
			return
		end

		local item = InventoryService.GetItem(player, instanceId)
		if not item then
			notify:FireClient(player, "Item not found in inventory!", "Error")
			return
		end

		if item.isDisplayed then
			notify:FireClient(player, "This item is already placed on a stand!", "Warning")
			return
		end

		local maxStands = EconomyService.GetDisplayCapacity(player)
		local stands = plotStands[plotId]
		if not stands then
			stands = {}
			plotStands[plotId] = stands
		end

		-- Find next empty stand or use requested
		local targetStand = requestedStandId or 1
		if stands[targetStand] ~= nil then
			-- Find any free stand
			targetStand = 0
			for s = 1, maxStands do
				if stands[s] == nil then
					targetStand = s
					break
				end
			end
		end

		if targetStand == 0 or targetStand > maxStands then
			notify:FireClient(player, "All display stands are occupied! Upgrade stand capacity.", "Warning")
			return
		end

		-- Place item
		stands[targetStand] = instanceId
		InventoryService.SetItemDisplayed(player, instanceId, true, targetStand)

		local def = CollectiblesConfig[item.itemId]
		local name = if def then def.name else item.itemId
		local rarity = if def then def.rarity else "Common"
		local income = if def then def.incomePerSecond else 2

		updatePhysicalStand(plotId, targetStand, name, rarity, income)
		EconomyService.ReplicateState(player)
		notify:FireClient(player, "Placed " .. name .. " on Stand #" .. targetStand .. "!", "Success")
	end)

	-- Handle RequestUndisplay
	local undisplayEvent = Network.GetEvent(Network.Events.RequestUndisplay)
	undisplayEvent.OnServerEvent:Connect(function(player: Player, standId: number)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)
		local plotId = PlotService.GetPlotForPlayer(player)
		if not plotId then return end

		local stands = plotStands[plotId]
		if not stands or not stands[standId] then
			notify:FireClient(player, "No item on this stand!", "Warning")
			return
		end

		local instanceId = stands[standId]
		stands[standId] = nil
		InventoryService.SetItemDisplayed(player, instanceId, false, nil)

		updatePhysicalStand(plotId, standId, nil, nil, nil)
		EconomyService.ReplicateState(player)
		notify:FireClient(player, "Removed item from Stand #" .. standId .. " back to inventory.", "Success")
	end)

	print("[DisplayService] Started.")
end

function DisplayService.OnPlayerRemoving(player: Player)
	if not PlotService then return end
	local plotId = PlotService.GetPlotForPlayer(player)
	if not plotId then return end

	local stands = plotStands[plotId]
	if stands then
		for s = 1, 6 do
			updatePhysicalStand(plotId, s, nil, nil, nil)
		end
		plotStands[plotId] = nil
	end
end

function DisplayService.GetPlayerIncomeRate(player: Player): number
	if not PlotService then return 0 end
	local plotId = PlotService.GetPlotForPlayer(player)
	if not plotId then return 0 end

	local stands = plotStands[plotId]
	if not stands then return 0 end

	local totalIncome = 0
	for _, instanceId in pairs(stands) do
		local item = InventoryService.GetItem(player, instanceId)
		if item then
			local def = CollectiblesConfig[item.itemId]
			if def then
				totalIncome += def.incomePerSecond
			end
		end
	end
	return totalIncome
end

return DisplayService
