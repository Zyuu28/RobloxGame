--!strict
--[[
	UnboxController — Client-side unboxing presentation and reveal.
	Authority: GDD §6, §12.1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local controllersFolder = script.Parent

local UIManager = require(controllersFolder:WaitForChild("UIManager") :: ModuleScript)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local CollectiblesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("CollectiblesConfig") :: ModuleScript)

local UnboxController = {}

function UnboxController.Init()
	UIManager.OnUnboxClaimClicked = function()
		UIManager.ShowToast("Collectible added to inventory!", "Success")
	end

	print("[UnboxController] Initialized.")
end

function UnboxController.Start()
	local unboxEvent = Network.GetEvent(Network.Events.UnboxReveal)
	unboxEvent.OnClientEvent:Connect(function(boxInfo, rolledItemId: string)
		local def = CollectiblesConfig[rolledItemId]
		local name = if def then def.name else rolledItemId
		local rarity = if def then def.rarity else "Common"
		local biomeId = if def then def.biomeId else "Urban"
		local income = if def then def.incomePerSecond else 2

		local itemInfo = {
			name = name,
			rarity = rarity,
			biomeId = biomeId,
			incomePerSecond = income,
		}

		UIManager.PlayUnboxSequence(boxInfo, itemInfo)
	end)

	print("[UnboxController] Started.")
end

return UnboxController
