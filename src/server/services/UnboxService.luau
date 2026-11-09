--!strict
--[[
	UnboxService — Manages the unboxing transaction, loot roll, and reward grant.
	Authority: GDD §6, §6.1 (AC-07, AC-08).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local LootTablesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("LootTablesConfig") :: ModuleScript)

local UnboxService = {}

local PlotService: any = nil
local CarryService: any = nil
local InventoryService: any = nil

function UnboxService.Init()
	print("[UnboxService] Initialized.")
end

function UnboxService.Start()
	local servicesFolder = ServerScriptService:WaitForChild("Services")
	PlotService = require(servicesFolder:WaitForChild("PlotService") :: ModuleScript)
	CarryService = require(servicesFolder:WaitForChild("CarryService") :: ModuleScript)
	InventoryService = require(servicesFolder:WaitForChild("InventoryService") :: ModuleScript)

	local unboxEvent = Network.GetEvent(Network.Events.RequestUnbox)
	unboxEvent.OnServerEvent:Connect(function(player: Player, plotId: string)
		local notify = Network.GetEvent(Network.Events.NotifyFeedback)

		-- 1. Validate plot ownership
		if not PlotService.IsPlotOwner(player, plotId) then
			notify:FireClient(player, "You can only unbox at your own plot!", "Error")
			return
		end

		-- Distance validation: player must be within 20 studs of their unbox pad
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local plotsFolder = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PlayerPlots")
		local plotModel = plotsFolder and plotsFolder:FindFirstChild(plotId)
		local pad = plotModel and plotModel:FindFirstChild("UnboxPad") :: BasePart?
		if hrp and pad and (hrp.Position - pad.Position).Magnitude > 22 then
			notify:FireClient(player, "You are too far from your unboxing pad!", "Error")
			return
		end

		-- Safezone validation: must be inside Safezone perimeter (R <= 85 studs)
		if hrp then
			local distFromCenter = math.sqrt(hrp.Position.X * hrp.Position.X + hrp.Position.Z * hrp.Position.Z)
			if distFromCenter > 90 then
				notify:FireClient(player, "You must reach the Safezone before unboxing!", "Error")
				return
			end
		end

		-- 2. Validate carried box
		local carriedBox = CarryService.GetCarriedBox(player)
		if not carriedBox then
			notify:FireClient(player, "You are not carrying a Mystery Box!", "Warning")
			return
		end

		-- 3. Validate inventory capacity BEFORE consuming box (AC-08)
		if InventoryService.IsFull(player) then
			notify:FireClient(player, "Inventory is full! Upgrade capacity before unboxing.", "Error")
			return
		end

		-- 4. Atomic transaction
		local boxInfo = {
			boxTypeId = carriedBox.boxTypeId,
			biomeId = carriedBox.biomeId,
		}

		-- Consume carried box
		CarryService.ClearCarriedBox(player)

		-- Roll reward from loot table for this Biome
		local rolledItemId = LootTablesConfig.RollItem(carriedBox.biomeId)

		-- Grant item to inventory
		local success, instanceId = InventoryService.AddItem(player, rolledItemId)
		if not success then
			notify:FireClient(player, "Failed to grant item. Please retry.", "Error")
			return
		end

		-- Trigger client suspense & reveal presentation
		local revealEvent = Network.GetEvent(Network.Events.UnboxReveal)
		revealEvent:FireClient(player, boxInfo, rolledItemId)

		print("[UnboxService] Granted " .. rolledItemId .. " to " .. player.Name)
	end)

	print("[UnboxService] Started.")
end

return UnboxService
