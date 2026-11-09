--!strict
--[[
	HUDController — Client-side heads-up display, UI orchestrator & desktop hotkeys.
	Authority: GDD §9, §17.
	
	Desktop Keyboard Controls:
	  - [E] or [B] / [I] : Toggle Collectible Inventory
	  - [U] or [P]       : Toggle Upgrade Shop
	  - [C]              : Claim Pending Bucks
	  - [Escape]         : Close any active modal
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local controllersFolder = script.Parent

-- Safe require with WaitForChild
local UIManager = require(controllersFolder:WaitForChild("UIManager") :: ModuleScript)
local InteractionController = require(controllersFolder:WaitForChild("InteractionController") :: ModuleScript)

-- Shared Network & Configs
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
local UpgradesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("UpgradesConfig") :: ModuleScript)

local HUDController = {}

-- Local Cache
local currentBucks = 0
local currentPendingBucks = 0
local currentIncomeRate = 0
local currentPlotId: string? = nil
local invLevel = 0
local dispLevel = 0
local speedLevel = 0
local currentBaseSpeed = 16

function HUDController.Init()
	UIManager.Init()

	-- Set up Callbacks from UI
	UIManager.OnClaimClicked = function()
		if not currentPlotId then
			UIManager.ShowToast("No plot assigned yet!", "Warning")
			return
		end
		local claimEvent = Network.GetEvent(Network.Events.RequestClaim)
		claimEvent:FireServer(currentPlotId)
	end

	UIManager.OnShopToggle = function()
		UIManager.ToggleShop()
	end

	UIManager.OnRobuxShopToggle = function()
		UIManager.ToggleRobuxShop()
	end

	UIManager.OnMapToggle = function()
		UIManager.ToggleMap()
	end

	UIManager.OnUpgradeInventory = function()
		local upgradeEvent = Network.GetEvent(Network.Events.RequestUpgrade)
		upgradeEvent:FireServer("InventoryCapacity")
	end

	UIManager.OnUpgradeDisplay = function()
		local upgradeEvent = Network.GetEvent(Network.Events.RequestUpgrade)
		upgradeEvent:FireServer("DisplayStandCapacity")
	end

	UIManager.OnUpgradeSpeed = function()
		local upgradeEvent = Network.GetEvent(Network.Events.RequestUpgrade)
		upgradeEvent:FireServer("WalkSpeed")
	end

	UIManager.OnDropBox = function()
		local dropEvent = Network.GetEvent(Network.Events.RequestDropBox)
		dropEvent:FireServer()
	end

	print("[HUDController] Initialized.")
end

function HUDController.Start()
	-- Listen for AssignedPlot attribute change
	player:GetAttributeChangedSignal("AssignedPlot"):Connect(function()
		local plot = player:GetAttribute("AssignedPlot")
		currentPlotId = if typeof(plot) == "string" then plot else nil
		UIManager.UpdatePlot(currentPlotId)
	end)
	local initPlot = player:GetAttribute("AssignedPlot")
	currentPlotId = if typeof(initPlot) == "string" then initPlot else nil
	UIManager.UpdatePlot(currentPlotId)

	-- Live Speedometer update function (Authority: AC-17)
	local function updateSpeedometerLive()
		local char = player.Character
		local humanoid = if char then char:FindFirstChildOfClass("Humanoid") else nil
		local isCarrying = (player:GetAttribute("CarryingBox") ~= nil and player:GetAttribute("CarryingBox") ~= "")

		local actualSpeed = 16
		if humanoid then
			actualSpeed = humanoid.WalkSpeed
		else
			local attrSpeed = player:GetAttribute("CurrentWalkSpeed")
			if typeof(attrSpeed) == "number" then
				actualSpeed = attrSpeed
			end
		end

		local attrLevel = player:GetAttribute("WalkSpeedLevel")
		local lvl = if typeof(attrLevel) == "number" then attrLevel else speedLevel
		UIManager.UpdateSpeedometer(actualSpeed, currentBaseSpeed, isCarrying, lvl)
	end

	-- Hook character humanoid walk speed changes
	local function hookCharacterSpeed(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(updateSpeedometerLive)
		end
		updateSpeedometerLive()
	end

	player.CharacterAdded:Connect(hookCharacterSpeed)
	if player.Character then
		hookCharacterSpeed(player.Character)
	end

	player:GetAttributeChangedSignal("CurrentWalkSpeed"):Connect(updateSpeedometerLive)
	player:GetAttributeChangedSignal("WalkSpeedLevel"):Connect(updateSpeedometerLive)

	-- Helper function to update carried box from attribute
	local function updateCarriedState()
		local carrying = player:GetAttribute("CarryingBox")
		if typeof(carrying) == "string" and carrying ~= "" then
			local parts = string.split(carrying, "_")
			local biomeId = parts[1] or "Urban"
			UIManager.UpdateCarriedBox({ boxTypeId = carrying, biomeId = biomeId })
		else
			UIManager.UpdateCarriedBox(nil)
		end
		updateSpeedometerLive()
	end

	-- Listen for CarryingBox attribute change
	player:GetAttributeChangedSignal("CarryingBox"):Connect(updateCarriedState)
	updateCarriedState()

	-- Listen for StateUpdate RemoteEvent
	local stateEvent = Network.GetEvent(Network.Events.StateUpdate)
	stateEvent.OnClientEvent:Connect(function(stateDelta)
		if stateDelta.bucks ~= nil then
			currentBucks = stateDelta.bucks
		end
		if stateDelta.pendingBucks ~= nil then
			currentPendingBucks = stateDelta.pendingBucks
		end
		if stateDelta.incomeRate ~= nil then
			currentIncomeRate = stateDelta.incomeRate
		end
		if stateDelta.inventoryCapacityLevel ~= nil then
			invLevel = stateDelta.inventoryCapacityLevel
		end
		if stateDelta.displayCapacityLevel ~= nil then
			dispLevel = stateDelta.displayCapacityLevel
		end
		if stateDelta.walkSpeedLevel ~= nil then
			speedLevel = stateDelta.walkSpeedLevel
		end
		if stateDelta.walkSpeed ~= nil then
			currentBaseSpeed = stateDelta.walkSpeed
		end

		UIManager.UpdateEconomy(currentBucks, currentPendingBucks, currentIncomeRate)

		-- Update upgrade cards (Inventory, Display, and WalkSpeed)
		local invDef = UpgradesConfig.InventoryCapacity
		local invCurCap = invDef.levels[invLevel + 1].newCapacity
		local invNextCost = if invLevel < 3 then invDef.levels[invLevel + 2].costBucks else 0

		local dispDef = UpgradesConfig.DisplayStandCapacity
		local dispCurCap = dispDef.levels[dispLevel + 1].newCapacity
		local dispNextCost = if dispLevel < 3 then dispDef.levels[dispLevel + 2].costBucks else 0

		local speedDef = UpgradesConfig.WalkSpeed
		local speedCurVal = if speedDef and speedDef.levels[speedLevel + 1] then speedDef.levels[speedLevel + 1].newCapacity else 16
		local speedNextCost = if speedDef and speedLevel < 3 then speedDef.levels[speedLevel + 2].costBucks else 0
		local speedNextVal = if speedDef and speedLevel < 3 then speedDef.levels[speedLevel + 2].newCapacity else speedCurVal

		UIManager.UpdateUpgrades(
			invLevel, invCurCap, invNextCost,
			dispLevel, dispCurCap, dispNextCost,
			speedLevel, speedCurVal, speedNextCost, speedNextVal
		)

		updateSpeedometerLive()
	end)

	-- Listen for Feedback RemoteEvent
	local notifyEvent = Network.GetEvent(Network.Events.NotifyFeedback)
	notifyEvent.OnClientEvent:Connect(function(message: string, alertType: string?)
		UIManager.ShowToast(message, alertType)
	end)

	------------------------------------------------------------------
	-- Desktop Hotkeys (Keyboard Input)
	------------------------------------------------------------------
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		-- Ignore when typing in chat or text boxes
		if gameProcessedEvent then return end

		local code = input.KeyCode

		-- [M] for World Map
		if code == Enum.KeyCode.M then
			UIManager.ToggleMap()

		-- [E], [B], [I], or [Tab] for Inventory
		elseif code == Enum.KeyCode.E or code == Enum.KeyCode.B or code == Enum.KeyCode.I or code == Enum.KeyCode.Tab then
			UIManager.ToggleInventory()

		-- [U] or [P] for Upgrade Shop
		elseif code == Enum.KeyCode.U or code == Enum.KeyCode.P then
			UIManager.ToggleShop()

		-- [R] for Robux Store
		elseif code == Enum.KeyCode.R then
			UIManager.ToggleRobuxShop()

		-- [Q] for Drop Box
		elseif code == Enum.KeyCode.Q then
			if UIManager.OnDropBox then
				UIManager.OnDropBox()
			end

		-- [C] for Claim Bucks
		elseif code == Enum.KeyCode.C then
			if UIManager.OnClaimClicked then
				UIManager.OnClaimClicked()
			end

		-- [Escape] to close active modals
		elseif code == Enum.KeyCode.Escape then
			if UIManager.IsAnyModalOpen() then
				UIManager.CloseAllModals()
			end
		end
	end)

	-- Desktop welcome toast showing keybinds
	if UserInputService.KeyboardEnabled then
		task.delay(1.5, function()
			UIManager.ShowToast("⌨️ Keys: [U] Upgrades · [E] Bag · [M] Map · [R] Shop · [Q] Drop Box · [C] Claim", "Success")
		end)
	end

	print("[HUDController] Started with desktop keyboard controls.")
end

return HUDController
