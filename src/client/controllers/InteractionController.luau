--!strict
--[[
	InteractionController — Handles world object interactions and proximity prompts.
	Authority: GDD §5.3, §9.
	
	Note: ProximityPrompts automatically support both desktop keyboard (E)
	and mobile touchscreen tap natively in Roblox!
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local controllersFolder = script.Parent

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)

local InteractionController = {}

local isHoldingPrompt = false

function InteractionController.IsHoldingPrompt(): boolean
	return isHoldingPrompt
end

function InteractionController.Init()
	print("[InteractionController] Initialized.")
end

function InteractionController.Start()
	-- Track when the player is actively holding a prompt button (e.g. holding E)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
		if triggeringPlayer == player then
			isHoldingPrompt = true
		end
	end)

	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
		if triggeringPlayer == player then
			isHoldingPrompt = false
		end
	end)

	-- Listen for any prompt triggered by the local player
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
		if triggeringPlayer ~= player then return end

		local promptAction = prompt.ActionText
		local parentPart = prompt.Parent :: Instance?
		if not parentPart then return end

		-- Check prompt type by tag or name
		if prompt:GetAttribute("PromptType") == "PickupBox" or parentPart:GetAttribute("WorldBoxId") ~= nil then
			local worldBoxId = parentPart:GetAttribute("WorldBoxId")
			if worldBoxId then
				local pickupEvent = Network.GetEvent(Network.Events.RequestPickup)
				pickupEvent:FireServer(worldBoxId)
			end
		elseif prompt:GetAttribute("PromptType") == "UnboxPad" or (parentPart:GetAttribute("PlotId") ~= nil and promptAction == "Unbox") then
			local plotId = parentPart:GetAttribute("PlotId") or player:GetAttribute("AssignedPlot")
			if plotId then
				local unboxEvent = Network.GetEvent(Network.Events.RequestUnbox)
				unboxEvent:FireServer(plotId)
			end
		elseif prompt:GetAttribute("PromptType") == "MoneyCollector" or promptAction == "Claim Bucks" then
			local plotId = parentPart:GetAttribute("PlotId") or player:GetAttribute("AssignedPlot")
			if plotId then
				local claimEvent = Network.GetEvent(Network.Events.RequestClaim)
				claimEvent:FireServer(plotId)
			end
		end
	end)

	print("[InteractionController] Started.")
end

return InteractionController
