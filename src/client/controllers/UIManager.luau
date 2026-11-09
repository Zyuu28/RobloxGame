--!strict
--[[
	UIManager — Programmatic UI Generation and Management for Steal a Mystery Box!
	Authority: GDD §9, §17 & WorldMapV1.png (Hub-and-Spoke Layout).
	
	Features:
	  - Stylized theme (dark slate, vibrant accents, UIStroke, UICorner)
	  - Mobile-ready (touch targets >= 44 logical px)
	  - Desktop-ready (custom hotkeys [E], [M], [U], [C], [ESC])
	  - Thumbstick/jump button zones preserved (bottom corners clear)
	  - HUD: Wallet Bucks, Pending Bucks + Claim, Carried Box, Plot info, Waypoint Bar
	  - Action Buttons: [M] MAP, [E] INVENTORY, [U] UPGRADES
	  - Modals: World Map Modal (Hub-and-Spoke), Inventory Window, Upgrade Shop, Unbox Reveal
	  - Feedback: Top toast notification system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BoxesConfig = require(sharedFolder:WaitForChild("Configs"):WaitForChild("BoxesConfig") :: ModuleScript)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UIManager = {}

local isDesktop = UserInputService.KeyboardEnabled

-- Visual Theme
local THEME = {
	Background = Color3.fromRGB(18, 22, 34),
	BackgroundTrans = 0.08,
	Surface = Color3.fromRGB(26, 32, 48),
	SurfaceHover = Color3.fromRGB(36, 44, 66),
	Stroke = Color3.fromRGB(60, 72, 100),
	StrokeGlow = Color3.fromRGB(90, 180, 255),
	
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(175, 185, 205),
	TextGreen = Color3.fromRGB(80, 230, 130),
	TextGold = Color3.fromRGB(255, 205, 50),
	
	ButtonPrimary = Color3.fromRGB(0, 150, 255),
	ButtonSuccess = Color3.fromRGB(46, 204, 113),
	ButtonWarning = Color3.fromRGB(243, 156, 18),
	ButtonDanger = Color3.fromRGB(231, 76, 60),
	ButtonDisabled = Color3.fromRGB(60, 65, 80),
	
	FontBold = Enum.Font.GothamBold,
	FontMedium = Enum.Font.GothamMedium,
}

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(76, 175, 80),
	Rare      = Color3.fromRGB(33, 150, 243),
	Epic      = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7),
	Secret    = Color3.fromRGB(255, 23, 68),
}

-- UI State Elements
local screenGui: ScreenGui
local hudContainer: Frame
local bucksLabel: TextLabel
local pendingLabel: TextLabel
local claimButton: TextButton
local boxLabel: TextLabel
local boxBadge: Frame
local plotLabel: TextLabel
local waypointLabel: TextLabel
local mapButton: TextButton
local inventoryButton: TextButton
local shopButton: TextButton

-- Modals
local worldMapModal: Frame
local currentWaypointTarget: Vector3? = nil
local currentWaypointName = "None"

local inventoryModal: Frame
local inventoryCapacityLabel: TextLabel
local inventoryGrid: ScrollingFrame
local inventoryFilter = "All"

local shopModal: Frame
local robuxShopModal: Frame
local shopBucksLabel: TextLabel
local invUpgradeLevelLabel: TextLabel
local invUpgradeCostLabel: TextLabel
local invUpgradeButton: TextButton
local dispUpgradeLevelLabel: TextLabel
local dispUpgradeCostLabel: TextLabel
local dispUpgradeButton: TextButton
local speedUpgradeLevelLabel: TextLabel
local speedUpgradeCostLabel: TextLabel
local speedUpgradeButton: TextButton

-- Speedometer HUD Elements
local speedometerContainer: Frame
local speedometerValueLabel: TextLabel
local speedometerStatusLabel: TextLabel
local speedometerBar: Frame

local unboxModal: Frame
local unboxSuspenseFrame: Frame
local unboxSuspenseText: TextLabel
local unboxProgressBar: Frame
local unboxRevealFrame: Frame
local unboxRarityBadge: TextLabel
local unboxItemName: TextLabel
local unboxBiomeLabel: TextLabel
local unboxIncomeLabel: TextLabel
local unboxClaimBtn: TextButton

local toastContainer: Frame
local toastLabel: TextLabel

-- Callbacks
UIManager.OnClaimClicked = nil :: (() -> ())?
UIManager.OnInventoryToggle = nil :: (() -> ())?
UIManager.OnShopToggle = nil :: (() -> ())?
UIManager.OnRobuxShopToggle = nil :: (() -> ())?
UIManager.OnRobuxPurchaseClicked = nil :: ((productKey: string, price: number) -> ())?
UIManager.OnMapToggle = nil :: (() -> ())?
UIManager.OnUpgradeInventory = nil :: (() -> ())?
UIManager.OnUpgradeDisplay = nil :: (() -> ())?
UIManager.OnUpgradeSpeed = nil :: (() -> ())?
UIManager.OnItemActionClicked = nil :: ((instanceId: string, action: string) -> ())?
UIManager.OnUnboxClaimClicked = nil :: (() -> ())?
UIManager.OnDropBox = nil :: (() -> ())?
UIManager.RefreshInventoryUI = nil :: (() -> ())?

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent: Instance, top: number, bottom: number, left: number, right: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top)
	pad.PaddingBottom = UDim.new(0, bottom)
	pad.PaddingLeft = UDim.new(0, left)
	pad.PaddingRight = UDim.new(0, right)
	pad.Parent = parent
	return pad
end

----------------------------------------------------------------------
-- Programmatic UI Construction
----------------------------------------------------------------------

function UIManager.Init()
	if screenGui then return end

	-- Root ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MysteryBoxUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	-- Helper for juicy button hover effects
	local function hookButtonHover(btn: TextButton)
		local origSize = btn.Size
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(origSize.X.Scale, origSize.X.Offset + 6, origSize.Y.Scale, origSize.Y.Offset)
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = origSize
			}):Play()
		end)
	end

	------------------------------------------------------------------
	-- 1. LEFT MENU: Vertical action pills (clean & small, like reference)
	------------------------------------------------------------------
	local leftMenu = Instance.new("Frame")
	leftMenu.Name = "LeftMenu"
	leftMenu.Size = UDim2.new(0, 96, 0, 128)
	leftMenu.Position = UDim2.new(0, 14, 0.40, 0)
	leftMenu.BackgroundTransparency = 1
	leftMenu.Parent = screenGui

	local leftList = Instance.new("UIListLayout")
	leftList.SortOrder = Enum.SortOrder.LayoutOrder
	leftList.Padding = UDim.new(0, 8)
	leftList.Parent = leftMenu

	-- Button 1: Upgrades [U] (In-game Bucks Upgrades)
	shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.LayoutOrder = 1
	shopButton.Size = UDim2.new(1, 0, 0, 36)
	shopButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	shopButton.Font = THEME.FontBold
	shopButton.TextSize = 13
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.Text = "⬆️ Upgrades"
	addCorner(shopButton, 8)
	addStroke(shopButton, Color3.fromRGB(110, 240, 160), 1.5)
	shopButton.Parent = leftMenu
	hookButtonHover(shopButton)

	shopButton.MouseButton1Click:Connect(function()
		if UIManager.OnShopToggle then
			UIManager.OnShopToggle()
		end
	end)

	-- Button 2: Collectibles Inventory [E] (Vibrant Sky Blue Pill)
	inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.LayoutOrder = 2
	inventoryButton.Size = UDim2.new(1, 0, 0, 36)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
	inventoryButton.Font = THEME.FontBold
	inventoryButton.TextSize = 13
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.Text = "🎒 Bag"
	addCorner(inventoryButton, 8)
	addStroke(inventoryButton, Color3.fromRGB(120, 220, 255), 1.5)
	inventoryButton.Parent = leftMenu
	hookButtonHover(inventoryButton)

	inventoryButton.MouseButton1Click:Connect(function()
		if UIManager.OnInventoryToggle then
			UIManager.OnInventoryToggle()
		end
	end)

	-- Button 3: World Map [M] (Vibrant Purple Pill)
	mapButton = Instance.new("TextButton")
	mapButton.Name = "MapButton"
	mapButton.LayoutOrder = 3
	mapButton.Size = UDim2.new(1, 0, 0, 36)
	mapButton.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
	mapButton.Font = THEME.FontBold
	mapButton.TextSize = 13
	mapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	mapButton.Text = "🗺️ Map"
	addCorner(mapButton, 8)
	addStroke(mapButton, Color3.fromRGB(200, 150, 255), 1.5)
	mapButton.Parent = leftMenu
	hookButtonHover(mapButton)

	mapButton.MouseButton1Click:Connect(function()
		if UIManager.OnMapToggle then
			UIManager.OnMapToggle()
		end
	end)

	------------------------------------------------------------------
	-- 2. RIGHT MENU: Quick-Action Square Icons (Like reference game)
	------------------------------------------------------------------
	local rightMenu = Instance.new("Frame")
	rightMenu.Name = "RightMenu"
	rightMenu.Size = UDim2.new(0, 38, 0, 84)
	rightMenu.Position = UDim2.new(1, -50, 0.44, 0)
	rightMenu.BackgroundTransparency = 1
	rightMenu.Parent = screenGui

	local rightList = Instance.new("UIListLayout")
	rightList.SortOrder = Enum.SortOrder.LayoutOrder
	rightList.Padding = UDim.new(0, 8)
	rightList.Parent = rightMenu

	-- Right Button 1: Robux Exclusive Shop (Opens Robux Store)
	local robuxShopBtn = Instance.new("TextButton")
	robuxShopBtn.Name = "RobuxShopButton"
	robuxShopBtn.LayoutOrder = 1
	robuxShopBtn.Size = UDim2.new(0, 38, 0, 38)
	robuxShopBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- Vibrant Gold
	robuxShopBtn.Font = THEME.FontBold
	robuxShopBtn.TextSize = 20
	robuxShopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxShopBtn.Text = "💎"
	addCorner(robuxShopBtn, 8)
	addStroke(robuxShopBtn, Color3.fromRGB(255, 235, 120), 1.5)
	robuxShopBtn.Parent = rightMenu
	hookButtonHover(robuxShopBtn)

	robuxShopBtn.MouseButton1Click:Connect(function()
		UIManager.ToggleRobuxShop()
	end)

	-- Quick Plot Waypoint Button (Points compass to plot)
	local plotQuickBtn = Instance.new("TextButton")
	plotQuickBtn.Name = "PlotQuickButton"
	plotQuickBtn.LayoutOrder = 2
	plotQuickBtn.Size = UDim2.new(0, 38, 0, 38)
	plotQuickBtn.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
	plotQuickBtn.Font = THEME.FontBold
	plotQuickBtn.TextSize = 18
	plotQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	plotQuickBtn.Text = "🧭"
	addCorner(plotQuickBtn, 8)
	addStroke(plotQuickBtn, Color3.fromRGB(120, 200, 255), 1.5)
	plotQuickBtn.Parent = rightMenu
	hookButtonHover(plotQuickBtn)

	plotQuickBtn.MouseButton1Click:Connect(function()
		UIManager.ToggleMap()
	end)

	------------------------------------------------------------------
	-- 3. BOTTOM-LEFT HUD: Compact Stats & Economy
	-- (Takes minimal screen area, completely frees center viewport)
	------------------------------------------------------------------
	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "BottomLeftStats"
	statsContainer.Size = UDim2.new(0, 180, 0, 86)
	statsContainer.Position = UDim2.new(0, 14, 1, -100)
	statsContainer.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	statsContainer.BackgroundTransparency = 0.5
	addCorner(statsContainer, 10)
	addStroke(statsContainer, THEME.Stroke, 1)
	addPadding(statsContainer, 6, 6, 8, 8)
	statsContainer.Parent = screenGui

	-- Speedometer Row
	speedometerContainer = Instance.new("Frame")
	speedometerContainer.Name = "SpeedRow"
	speedometerContainer.Size = UDim2.new(1, 0, 0, 20)
	speedometerContainer.BackgroundTransparency = 1
	speedometerContainer.Parent = statsContainer

	speedometerValueLabel = Instance.new("TextLabel")
	speedometerValueLabel.Name = "SpeedValue"
	speedometerValueLabel.Size = UDim2.new(0.68, 0, 1, 0)
	speedometerValueLabel.BackgroundTransparency = 1
	speedometerValueLabel.Font = THEME.FontBold
	speedometerValueLabel.TextSize = 14
	speedometerValueLabel.TextColor3 = Color3.fromRGB(0, 235, 255)
	speedometerValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedometerValueLabel.Text = "⚡ 16.0 studs/s"
	speedometerValueLabel.Parent = speedometerContainer

	speedometerStatusLabel = Instance.new("TextLabel")
	speedometerStatusLabel.Name = "SpeedStatus"
	speedometerStatusLabel.Size = UDim2.new(0.32, 0, 1, 0)
	speedometerStatusLabel.Position = UDim2.new(0.68, 0, 0, 0)
	speedometerStatusLabel.BackgroundTransparency = 1
	speedometerStatusLabel.Font = THEME.FontBold
	speedometerStatusLabel.TextSize = 10
	speedometerStatusLabel.TextColor3 = THEME.TextSecondary
	speedometerStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
	speedometerStatusLabel.Text = "LVL 0"
	speedometerStatusLabel.Parent = speedometerContainer

	-- Speed Mini-Progress Bar (subtle 2px)
	local speedBarBg = Instance.new("Frame")
	speedBarBg.Name = "SpeedBarBg"
	speedBarBg.Size = UDim2.new(1, 0, 0, 2)
	speedBarBg.Position = UDim2.new(0, 0, 0, 21)
	speedBarBg.BackgroundColor3 = Color3.fromRGB(30, 38, 55)
	speedBarBg.BorderSizePixel = 0
	speedBarBg.Parent = statsContainer

	speedometerBar = Instance.new("Frame")
	speedometerBar.Name = "SpeedBar"
	speedometerBar.Size = UDim2.new(16 / 50, 0, 1, 0)
	speedometerBar.BackgroundColor3 = Color3.fromRGB(0, 235, 255)
	speedometerBar.BorderSizePixel = 0
	speedometerBar.Parent = speedBarBg

	-- Bucks Currency Row
	bucksLabel = Instance.new("TextLabel")
	bucksLabel.Name = "BucksLabel"
	bucksLabel.Size = UDim2.new(1, 0, 0, 22)
	bucksLabel.Position = UDim2.new(0, 0, 0, 25)
	bucksLabel.BackgroundTransparency = 1
	bucksLabel.Font = THEME.FontBold
	bucksLabel.TextSize = 16
	bucksLabel.TextColor3 = THEME.TextGreen
	bucksLabel.TextXAlignment = Enum.TextXAlignment.Left
	bucksLabel.Text = "💵 $0 Bucks"
	bucksLabel.Parent = statsContainer

	pendingLabel = Instance.new("TextLabel")
	pendingLabel.Name = "PendingLabel"
	pendingLabel.Size = UDim2.new(1, 0, 0, 14)
	pendingLabel.Position = UDim2.new(0, 0, 0, 46)
	pendingLabel.BackgroundTransparency = 1
	pendingLabel.Font = THEME.FontMedium
	pendingLabel.TextSize = 10
	pendingLabel.TextColor3 = THEME.TextSecondary
	pendingLabel.TextXAlignment = Enum.TextXAlignment.Left
	pendingLabel.Text = "⏳ Pending: +$0"
	pendingLabel.Parent = statsContainer

	-- Claim Button + Plot Label
	claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0.50, 0, 0, 22)
	claimButton.Position = UDim2.new(0, 0, 1, -22)
	claimButton.BackgroundColor3 = THEME.ButtonDisabled
	claimButton.Font = THEME.FontBold
	claimButton.TextSize = 10
	claimButton.TextColor3 = THEME.TextPrimary
	claimButton.Text = "CLAIM [C]"
	addCorner(claimButton, 5)
	claimButton.Parent = statsContainer

	claimButton.MouseButton1Click:Connect(function()
		if UIManager.OnClaimClicked then
			UIManager.OnClaimClicked()
		end
	end)

	plotLabel = Instance.new("TextLabel")
	plotLabel.Name = "PlotLabel"
	plotLabel.Size = UDim2.new(0.48, 0, 0, 22)
	plotLabel.Position = UDim2.new(0.52, 0, 1, -22)
	plotLabel.BackgroundTransparency = 1
	plotLabel.Font = THEME.FontBold
	plotLabel.TextSize = 10
	plotLabel.TextColor3 = THEME.TextGold
	plotLabel.TextXAlignment = Enum.TextXAlignment.Right
	plotLabel.Text = "🏡 Plot: ..."
	plotLabel.Parent = statsContainer

	------------------------------------------------------------------
	-- 4. CENTER & TOP: 100% EMPTY (No permanent HUD elements!)
	------------------------------------------------------------------
	waypointLabel = Instance.new("TextLabel")
	waypointLabel.Name = "ZoneRadar"
	waypointLabel.Size = UDim2.new(0, 180, 0, 18)
	waypointLabel.Position = UDim2.new(0, 14, 1, -122) -- Tucked right above bottom-left stats
	waypointLabel.BackgroundTransparency = 1
	waypointLabel.Font = THEME.FontMedium
	waypointLabel.TextSize = 10
	waypointLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	waypointLabel.TextXAlignment = Enum.TextXAlignment.Left
	waypointLabel.Text = "🛡️ Safezone Hub"
	waypointLabel.Parent = screenGui

	-- Carried Box Dynamic Alert (ONLY visible when carrying a box!)
	boxBadge = Instance.new("Frame")
	boxBadge.Name = "CarriedBoxAlert"
	boxBadge.Size = UDim2.new(0, 340, 0, 36)
	boxBadge.Position = UDim2.new(0.5, -170, 0, 16)
	boxBadge.BackgroundColor3 = Color3.fromRGB(25, 15, 25)
	boxBadge.BackgroundTransparency = 0.2
	boxBadge.Visible = false -- HIDDEN by default!
	addCorner(boxBadge, 8)
	addStroke(boxBadge, Color3.fromRGB(255, 80, 80), 1.5)
	boxBadge.Parent = screenGui

	boxLabel = Instance.new("TextLabel")
	boxLabel.Name = "BoxLabel"
	boxLabel.Size = UDim2.new(1, -80, 1, 0)
	boxLabel.BackgroundTransparency = 1
	boxLabel.Font = THEME.FontBold
	boxLabel.TextSize = 11
	boxLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	boxLabel.Text = "🚨 CARRYING BOX · RUN TO SAFEZONE! 🚨"
	boxLabel.Parent = boxBadge

	-- DROP button inside the carried box alert
	local dropBtn = Instance.new("TextButton")
	dropBtn.Name = "DropButton"
	dropBtn.Size = UDim2.new(0, 68, 0, 26)
	dropBtn.Position = UDim2.new(1, -73, 0.5, -13)
	dropBtn.BackgroundColor3 = THEME.ButtonDanger
	dropBtn.Font = THEME.FontBold
	dropBtn.TextSize = 10
	dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropBtn.Text = "DROP [Q]"
	addCorner(dropBtn, 6)
	dropBtn.Parent = boxBadge
	dropBtn.MouseButton1Click:Connect(function()
		if UIManager.OnDropBox then
			UIManager.OnDropBox()
		end
	end)

	------------------------------------------------------------------
	-- 4. INTERACTIVE WORLD MAP MODAL (Hub-and-Spoke WorldMapV1.png)
	------------------------------------------------------------------
	worldMapModal = Instance.new("Frame")
	worldMapModal.Name = "WorldMapModal"
	worldMapModal.Size = UDim2.new(0, 720, 0, 520)
	worldMapModal.Position = UDim2.new(0.5, -360, 0.5, -260)
	worldMapModal.BackgroundColor3 = THEME.Background
	worldMapModal.BackgroundTransparency = 0.05
	worldMapModal.Visible = false
	addCorner(worldMapModal, 16)
	addStroke(worldMapModal, THEME.StrokeGlow, 2)
	addPadding(worldMapModal, 14, 14, 16, 16)
	worldMapModal.Parent = screenGui

	-- Map Header
	local mapHeader = Instance.new("Frame")
	mapHeader.Size = UDim2.new(1, 0, 0, 48)
	mapHeader.BackgroundTransparency = 1
	mapHeader.Parent = worldMapModal

	local mapTitle = Instance.new("TextLabel")
	mapTitle.Size = UDim2.new(0.65, 0, 0.6, 0)
	mapTitle.BackgroundTransparency = 1
	mapTitle.Font = THEME.FontBold
	mapTitle.TextSize = 18
	mapTitle.TextColor3 = THEME.TextPrimary
	mapTitle.TextXAlignment = Enum.TextXAlignment.Left
	mapTitle.Text = "🗺️ WORLD RADAR & BIOME MAP"
	mapTitle.Parent = mapHeader

	local mapSub = Instance.new("TextLabel")
	mapSub.Size = UDim2.new(0.65, 0, 0.4, 0)
	mapSub.Position = UDim2.new(0, 0, 0.6, 0)
	mapSub.BackgroundTransparency = 1
	mapSub.Font = THEME.FontMedium
	mapSub.TextSize = 12
	mapSub.TextColor3 = THEME.TextSecondary
	mapSub.TextXAlignment = Enum.TextXAlignment.Left
	mapSub.Text = "Hub-and-Spoke Layout · Safezone Plaza & 5 Biome Sectors"
	mapSub.Parent = mapHeader

	local compassLabel = Instance.new("TextLabel")
	compassLabel.Size = UDim2.new(0.2, 0, 1, 0)
	compassLabel.Position = UDim2.new(0.68, 0, 0, 0)
	compassLabel.BackgroundTransparency = 1
	compassLabel.Font = THEME.FontBold
	compassLabel.TextSize = 15
	compassLabel.TextColor3 = THEME.TextGold
	compassLabel.Text = "🧭 NORTH ↑"
	compassLabel.Parent = mapHeader

	local mapCloseBtn = Instance.new("TextButton")
	mapCloseBtn.Size = UDim2.new(0, 68, 0, 44) -- >= 44px
	mapCloseBtn.Position = UDim2.new(1, -68, 0, 0)
	mapCloseBtn.BackgroundColor3 = THEME.ButtonDanger
	mapCloseBtn.Font = THEME.FontBold
	mapCloseBtn.TextSize = 14
	mapCloseBtn.TextColor3 = THEME.TextPrimary
	mapCloseBtn.Text = if isDesktop then "✕ [ESC]" else "✕"
	addCorner(mapCloseBtn, 8)
	mapCloseBtn.Parent = mapHeader

	mapCloseBtn.MouseButton1Click:Connect(function()
		worldMapModal.Visible = false
	end)

	-- Map Canvas Surface
	local mapCanvas = Instance.new("Frame")
	mapCanvas.Name = "MapCanvas"
	mapCanvas.Size = UDim2.new(1, 0, 1, -56)
	mapCanvas.Position = UDim2.new(0, 0, 0, 56)
	mapCanvas.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	addCorner(mapCanvas, 12)
	addStroke(mapCanvas, THEME.Stroke, 1)
	mapCanvas.Parent = worldMapModal

	-- Connecting Road Line graphics (Hub-and-Spoke)
	local function drawSpokeRoad(name: string, p0: Vector2, p1: Vector2)
		local line = Instance.new("Frame")
		line.Name = name
		local dist = (p0 - p1).Magnitude
		local center = (p0 + p1) / 2
		local rot = math.deg(math.atan2(p1.Y - p0.Y, p1.X - p0.X))
		line.Size = UDim2.new(0, dist, 0, 6)
		line.Position = UDim2.new(0, center.X - dist / 2, 0, center.Y - 3)
		line.Rotation = rot
		line.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
		addCorner(line, 3)
		line.Parent = mapCanvas
	end

	-- Center Hub: SAFEZONE
	local centerHub = Instance.new("Frame")
	centerHub.Name = "SafezoneHub"
	centerHub.Size = UDim2.new(0, 180, 0, 180)
	centerHub.Position = UDim2.new(0.5, -90, 0.5, -80)
	centerHub.BackgroundColor3 = Color3.fromRGB(25, 34, 52)
	addCorner(centerHub, 90) -- Circular
	addStroke(centerHub, Color3.fromRGB(0, 200, 255), 2.5)
	centerHub.Parent = mapCanvas

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(1, 0, 0, 32)
	hubTitle.Position = UDim2.new(0, 0, 0, 18)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Font = THEME.FontBold
	hubTitle.TextSize = 14
	hubTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
	hubTitle.Text = "🛡️ SAFEZONE HUB"
	hubTitle.Parent = centerHub

	local hubDesc = Instance.new("TextLabel")
	hubDesc.Size = UDim2.new(1, 0, 0, 36)
	hubDesc.Position = UDim2.new(0, 0, 0, 50)
	hubDesc.BackgroundTransparency = 1
	hubDesc.Font = THEME.FontMedium
	hubDesc.TextSize = 11
	hubDesc.TextColor3 = THEME.TextSecondary
	hubDesc.Text = "⭐ Player Spawn\n8 Circular Plots Ring"
	hubDesc.Parent = centerHub

	local trackPlotBtn = Instance.new("TextButton")
	trackPlotBtn.Size = UDim2.new(0, 120, 0, 36)
	trackPlotBtn.Position = UDim2.new(0.5, -60, 1, -48)
	trackPlotBtn.BackgroundColor3 = THEME.ButtonSuccess
	trackPlotBtn.Font = THEME.FontBold
	trackPlotBtn.TextSize = 11
	trackPlotBtn.TextColor3 = THEME.TextPrimary
	trackPlotBtn.Text = "🎯 TRACK PLOT"
	addCorner(trackPlotBtn, 8)
	trackPlotBtn.Parent = centerHub

	trackPlotBtn.MouseButton1Click:Connect(function()
		local assignedPlot = player:GetAttribute("AssignedPlot")
		if typeof(assignedPlot) == "string" then
			local plotsFolder = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PlayerPlots")
			local plotModel = plotsFolder and plotsFolder:FindFirstChild(assignedPlot)
			if plotModel and plotModel.PrimaryPart then
				currentWaypointTarget = plotModel.PrimaryPart.Position
				currentWaypointName = "My Plot (" .. assignedPlot .. ")"
				UIManager.ShowToast("🎯 Waypoint set to " .. currentWaypointName, "Success")
				worldMapModal.Visible = false
			end
		else
			UIManager.ShowToast("No plot assigned yet!", "Warning")
		end
	end)

	-- Biome Card Generator
	local function createBiomeNode(bName: string, title: string, subtitle: string, status: string, color: Color3, pos: UDim2, targetPos: Vector3, isLocked: boolean)
		local node = Instance.new("Frame")
		node.Name = "Biome_" .. bName
		node.Size = UDim2.new(0, 160, 0, 110)
		node.Position = pos
		node.BackgroundColor3 = THEME.Surface
		addCorner(node, 12)
		addStroke(node, color, 2)
		addPadding(node, 8, 8, 10, 10)

		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.new(1, 0, 0, 22)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = THEME.FontBold
		tLbl.TextSize = 14
		tLbl.TextColor3 = color
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = title
		tLbl.Parent = node

		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, 0, 0, 18)
		subLbl.Position = UDim2.new(0, 0, 0, 22)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = THEME.FontMedium
		subLbl.TextSize = 11
		subLbl.TextColor3 = THEME.TextSecondary
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.Text = subtitle
		subLbl.Parent = node

		local stLbl = Instance.new("TextLabel")
		stLbl.Size = UDim2.new(1, 0, 0, 20)
		stLbl.Position = UDim2.new(0, 0, 0, 42)
		stLbl.BackgroundTransparency = 1
		stLbl.Font = THEME.FontBold
		stLbl.TextSize = 11
		stLbl.TextColor3 = isLocked and THEME.ButtonDisabled or THEME.TextGreen
		stLbl.TextXAlignment = Enum.TextXAlignment.Left
		stLbl.Text = status
		stLbl.Parent = node

		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(1, 0, 0, 32)
		actionBtn.Position = UDim2.new(0, 0, 1, -32)
		actionBtn.BackgroundColor3 = isLocked and THEME.ButtonDisabled or THEME.ButtonPrimary
		actionBtn.Font = THEME.FontBold
		actionBtn.TextSize = 11
		actionBtn.TextColor3 = THEME.TextPrimary
		actionBtn.Text = isLocked and "LOCKED" or "TRACK BIOME"
		addCorner(actionBtn, 6)
		actionBtn.Parent = node

		if not isLocked then
			actionBtn.MouseButton1Click:Connect(function()
				currentWaypointTarget = targetPos
				currentWaypointName = bName
				UIManager.ShowToast("🎯 Waypoint set to " .. bName .. " Biome!", "Success")
				worldMapModal.Visible = false
			end)
		end

		node.Parent = mapCanvas
		return node
	end

	-- 1. URBAN (North-West / Top-Left)
	createBiomeNode("Urban", "🏙️ URBAN", "City Streets", "🟢 ACTIVE (MVP)", Color3.fromRGB(40, 150, 255), UDim2.new(0.04, 0, 0.08, 0), Vector3.new(-160, 0.5, 160), false)

	-- 2. SLUMS (South-West / Bottom-Left)
	createBiomeNode("Slums", "🏚️ SLUMS", "Backstreets & Scrap", "🟢 ACTIVE (MVP)", Color3.fromRGB(220, 110, 40), UDim2.new(0.04, 0, 0.68, 0), Vector3.new(-160, 0.5, -160), false)

	-- 3. MOUNTAIN (North / Top-Center)
	createBiomeNode("Mountain", "🏔️ MOUNTAIN", "Cliffs & Mines", "🔒 LOCKED (Phase 5)", Color3.fromRGB(46, 140, 80), UDim2.new(0.5, -80, 0.02, 0), Vector3.new(0, 0.5, 200), true)

	-- 4. SPACE (North-East / Top-Right)
	createBiomeNode("Space", "🚀 SPACE", "Cosmic Station", "🔒 LOCKED (Phase 5)", Color3.fromRGB(150, 60, 240), UDim2.new(0.96, -160, 0.08, 0), Vector3.new(160, 0.5, 160), true)

	-- 5. OCEAN (South-East / Bottom-Right)
	createBiomeNode("Ocean", "🌊 OCEAN", "Reefs & Ships", "🔒 LOCKED (Phase 5)", Color3.fromRGB(0, 180, 220), UDim2.new(0.96, -160, 0.68, 0), Vector3.new(160, 0.5, -160), true)

	------------------------------------------------------------------
	-- 5. INVENTORY MODAL
	------------------------------------------------------------------
	inventoryModal = Instance.new("Frame")
	inventoryModal.Name = "InventoryModal"
	inventoryModal.Size = UDim2.new(0, 600, 0, 460)
	inventoryModal.Position = UDim2.new(0.5, -300, 0.5, -230)
	inventoryModal.BackgroundColor3 = THEME.Background
	inventoryModal.BackgroundTransparency = THEME.BackgroundTrans
	inventoryModal.Visible = false
	addCorner(inventoryModal, 14)
	addStroke(inventoryModal, THEME.StrokeGlow, 2)
	addPadding(inventoryModal, 14, 14, 16, 16)
	inventoryModal.Parent = screenGui

	local invHeader = Instance.new("Frame")
	invHeader.Size = UDim2.new(1, 0, 0, 48)
	invHeader.BackgroundTransparency = 1
	invHeader.Parent = inventoryModal

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(0.48, 0, 1, 0)
	invTitle.BackgroundTransparency = 1
	invTitle.Font = THEME.FontBold
	invTitle.TextSize = 18
	invTitle.TextColor3 = THEME.TextPrimary
	invTitle.TextXAlignment = Enum.TextXAlignment.Left
	invTitle.Text = if isDesktop then "🎒 INVENTORY [E to Toggle]" else "🎒 INVENTORY"
	invTitle.Parent = invHeader

	inventoryCapacityLabel = Instance.new("TextLabel")
	inventoryCapacityLabel.Size = UDim2.new(0.32, 0, 1, 0)
	inventoryCapacityLabel.Position = UDim2.new(0.48, 0, 0, 0)
	inventoryCapacityLabel.BackgroundTransparency = 1
	inventoryCapacityLabel.Font = THEME.FontBold
	inventoryCapacityLabel.TextSize = 14
	inventoryCapacityLabel.TextColor3 = THEME.TextGold
	inventoryCapacityLabel.TextXAlignment = Enum.TextXAlignment.Right
	inventoryCapacityLabel.Text = "Capacity: 0 / 20"
	inventoryCapacityLabel.Parent = invHeader

	local invCloseBtn = Instance.new("TextButton")
	invCloseBtn.Size = UDim2.new(0, 70, 0, 44) -- >= 44px
	invCloseBtn.Position = UDim2.new(1, -70, 0, 0)
	invCloseBtn.BackgroundColor3 = THEME.ButtonDanger
	invCloseBtn.Font = THEME.FontBold
	invCloseBtn.TextSize = 14
	invCloseBtn.TextColor3 = THEME.TextPrimary
	invCloseBtn.Text = if isDesktop then "✕ [ESC]" else "✕"
	addCorner(invCloseBtn, 8)
	invCloseBtn.Parent = invHeader

	invCloseBtn.MouseButton1Click:Connect(function()
		inventoryModal.Visible = false
	end)

	local filterBar = Instance.new("Frame")
	filterBar.Size = UDim2.new(1, 0, 0, 40)
	filterBar.Position = UDim2.new(0, 0, 0, 52)
	filterBar.BackgroundTransparency = 1
	filterBar.Parent = inventoryModal

	local filters = { "All", "Urban", "Slums", "Rare+" }
	for i, fName in ipairs(filters) do
		local fBtn = Instance.new("TextButton")
		fBtn.Size = UDim2.new(0, 95, 0, 36)
		fBtn.Position = UDim2.new(0, (i - 1) * 102, 0, 0)
		fBtn.BackgroundColor3 = (fName == "All") and THEME.ButtonPrimary or THEME.Surface
		fBtn.Font = THEME.FontBold
		fBtn.TextSize = 13
		fBtn.TextColor3 = THEME.TextPrimary
		fBtn.Text = fName
		addCorner(fBtn, 6)
		fBtn.Parent = filterBar

		fBtn.MouseButton1Click:Connect(function()
			inventoryFilter = fName
			for _, child in filterBar:GetChildren() do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = (child.Text == fName) and THEME.ButtonPrimary or THEME.Surface
				end
			end
			if UIManager.RefreshInventoryUI then
				UIManager.RefreshInventoryUI()
			end
		end)
	end

	inventoryGrid = Instance.new("ScrollingFrame")
	inventoryGrid.Size = UDim2.new(1, 0, 1, -100)
	inventoryGrid.Position = UDim2.new(0, 0, 0, 96)
	inventoryGrid.BackgroundTransparency = 1
	inventoryGrid.ScrollBarThickness = 6
	inventoryGrid.ScrollBarImageColor3 = THEME.StrokeGlow
	inventoryGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryGrid.Parent = inventoryModal

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 180, 0, 150)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.Parent = inventoryGrid

	------------------------------------------------------------------
	-- 6. UPGRADE SHOP MODAL (Capacity & Speed Upgrades)
	------------------------------------------------------------------
	shopModal = Instance.new("Frame")
	shopModal.Name = "ShopModal"
	shopModal.Size = UDim2.new(0, 540, 0, 460)
	shopModal.Position = UDim2.new(0.5, -270, 0.5, -230)
	shopModal.BackgroundColor3 = THEME.Background
	shopModal.BackgroundTransparency = THEME.BackgroundTrans
	shopModal.Visible = false
	addCorner(shopModal, 14)
	addStroke(shopModal, THEME.TextGold, 2)
	addPadding(shopModal, 14, 14, 16, 16)
	shopModal.Parent = screenGui

	local shopHeader = Instance.new("Frame")
	shopHeader.Size = UDim2.new(1, 0, 0, 48)
	shopHeader.BackgroundTransparency = 1
	shopHeader.Parent = shopModal

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(0.5, 0, 1, 0)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Font = THEME.FontBold
	shopTitle.TextSize = 18
	shopTitle.TextColor3 = THEME.TextGold
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Text = if isDesktop then "🛒 SHOP [U to Toggle]" else "🛒 UPGRADE SHOP"
	shopTitle.Parent = shopHeader

	shopBucksLabel = Instance.new("TextLabel")
	shopBucksLabel.Size = UDim2.new(0.32, 0, 1, 0)
	shopBucksLabel.Position = UDim2.new(0.5, 0, 0, 0)
	shopBucksLabel.BackgroundTransparency = 1
	shopBucksLabel.Font = THEME.FontBold
	shopBucksLabel.TextSize = 15
	shopBucksLabel.TextColor3 = THEME.TextGreen
	shopBucksLabel.TextXAlignment = Enum.TextXAlignment.Right
	shopBucksLabel.Text = "Wallet: $0"
	shopBucksLabel.Parent = shopHeader

	local shopCloseBtn = Instance.new("TextButton")
	shopCloseBtn.Size = UDim2.new(0, 70, 0, 44) -- >= 44px
	shopCloseBtn.Position = UDim2.new(1, -70, 0, 0)
	shopCloseBtn.BackgroundColor3 = THEME.ButtonDanger
	shopCloseBtn.Font = THEME.FontBold
	shopCloseBtn.TextSize = 14
	shopCloseBtn.TextColor3 = THEME.TextPrimary
	shopCloseBtn.Text = if isDesktop then "✕ [ESC]" else "✕"
	addCorner(shopCloseBtn, 8)
	shopCloseBtn.Parent = shopHeader

	shopCloseBtn.MouseButton1Click:Connect(function()
		shopModal.Visible = false
	end)

	local shopList = Instance.new("ScrollingFrame")
	shopList.Name = "ShopList"
	shopList.Size = UDim2.new(1, 0, 1, -54)
	shopList.Position = UDim2.new(0, 0, 0, 52)
	shopList.BackgroundTransparency = 1
	shopList.ScrollBarThickness = 4
	shopList.ScrollBarImageColor3 = THEME.Stroke
	shopList.CanvasSize = UDim2.new(0, 0, 0, 390)
	shopList.Parent = shopModal

	local shopListLayout = Instance.new("UIListLayout")
	shopListLayout.Padding = UDim.new(0, 10)
	shopListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopListLayout.Parent = shopList

	-- Card 1: Inventory Capacity
	local invCard = Instance.new("Frame")
	invCard.Name = "InvCard"
	invCard.Size = UDim2.new(1, -6, 0, 115)
	invCard.LayoutOrder = 1
	invCard.BackgroundColor3 = THEME.Surface
	addCorner(invCard, 10)
	addStroke(invCard, THEME.Stroke, 1.5)
	addPadding(invCard, 10, 10, 12, 12)
	invCard.Parent = shopList

	local invCardTitle = Instance.new("TextLabel")
	invCardTitle.Size = UDim2.new(0.65, 0, 0, 26)
	invCardTitle.BackgroundTransparency = 1
	invCardTitle.Font = THEME.FontBold
	invCardTitle.TextSize = 16
	invCardTitle.TextColor3 = THEME.TextPrimary
	invCardTitle.TextXAlignment = Enum.TextXAlignment.Left
	invCardTitle.Text = "📦 Inventory Capacity"
	invCardTitle.Parent = invCard

	invUpgradeLevelLabel = Instance.new("TextLabel")
	invUpgradeLevelLabel.Size = UDim2.new(0.65, 0, 0, 22)
	invUpgradeLevelLabel.Position = UDim2.new(0, 0, 0, 28)
	invUpgradeLevelLabel.BackgroundTransparency = 1
	invUpgradeLevelLabel.Font = THEME.FontMedium
	invUpgradeLevelLabel.TextSize = 13
	invUpgradeLevelLabel.TextColor3 = THEME.TextSecondary
	invUpgradeLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
	invUpgradeLevelLabel.Text = "Level 0: 20 slots → Next: 30 slots"
	invUpgradeLevelLabel.Parent = invCard

	invUpgradeCostLabel = Instance.new("TextLabel")
	invUpgradeCostLabel.Size = UDim2.new(0.65, 0, 0, 24)
	invUpgradeCostLabel.Position = UDim2.new(0, 0, 0, 52)
	invUpgradeCostLabel.BackgroundTransparency = 1
	invUpgradeCostLabel.Font = THEME.FontBold
	invUpgradeCostLabel.TextSize = 15
	invUpgradeCostLabel.TextColor3 = THEME.TextGreen
	invUpgradeCostLabel.TextXAlignment = Enum.TextXAlignment.Left
	invUpgradeCostLabel.Text = "Cost: $150 Bucks"
	invUpgradeCostLabel.Parent = invCard

	invUpgradeButton = Instance.new("TextButton")
	invUpgradeButton.Size = UDim2.new(0, 130, 0, 48) -- >= 44px
	invUpgradeButton.Position = UDim2.new(1, -130, 0.5, -24)
	invUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
	invUpgradeButton.Font = THEME.FontBold
	invUpgradeButton.TextSize = 15
	invUpgradeButton.TextColor3 = THEME.TextPrimary
	invUpgradeButton.Text = "UPGRADE"
	addCorner(invUpgradeButton, 8)
	invUpgradeButton.Parent = invCard

	invUpgradeButton.MouseButton1Click:Connect(function()
		if UIManager.OnUpgradeInventory then
			UIManager.OnUpgradeInventory()
		end
	end)

	-- Card 2: Display Stand Capacity
	local dispCard = Instance.new("Frame")
	dispCard.Name = "DispCard"
	dispCard.Size = UDim2.new(1, -6, 0, 115)
	dispCard.LayoutOrder = 2
	dispCard.BackgroundColor3 = THEME.Surface
	addCorner(dispCard, 10)
	addStroke(dispCard, THEME.Stroke, 1.5)
	addPadding(dispCard, 10, 10, 12, 12)
	dispCard.Parent = shopList

	local dispCardTitle = Instance.new("TextLabel")
	dispCardTitle.Size = UDim2.new(0.65, 0, 0, 26)
	dispCardTitle.BackgroundTransparency = 1
	dispCardTitle.Font = THEME.FontBold
	dispCardTitle.TextSize = 16
	dispCardTitle.TextColor3 = THEME.TextPrimary
	dispCardTitle.TextXAlignment = Enum.TextXAlignment.Left
	dispCardTitle.Text = "🏛️ Display Stand Capacity"
	dispCardTitle.Parent = dispCard

	dispUpgradeLevelLabel = Instance.new("TextLabel")
	dispUpgradeLevelLabel.Size = UDim2.new(0.65, 0, 0, 22)
	dispUpgradeLevelLabel.Position = UDim2.new(0, 0, 0, 28)
	dispUpgradeLevelLabel.BackgroundTransparency = 1
	dispUpgradeLevelLabel.Font = THEME.FontMedium
	dispUpgradeLevelLabel.TextSize = 13
	dispUpgradeLevelLabel.TextColor3 = THEME.TextSecondary
	dispUpgradeLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
	dispUpgradeLevelLabel.Text = "Level 0: 3 stands → Next: 4 stands"
	dispUpgradeLevelLabel.Parent = dispCard

	dispUpgradeCostLabel = Instance.new("TextLabel")
	dispUpgradeCostLabel.Size = UDim2.new(0.65, 0, 0, 24)
	dispUpgradeCostLabel.Position = UDim2.new(0, 0, 0, 52)
	dispUpgradeCostLabel.BackgroundTransparency = 1
	dispUpgradeCostLabel.Font = THEME.FontBold
	dispUpgradeCostLabel.TextSize = 15
	dispUpgradeCostLabel.TextColor3 = THEME.TextGreen
	dispUpgradeCostLabel.TextXAlignment = Enum.TextXAlignment.Left
	dispUpgradeCostLabel.Text = "Cost: $250 Bucks"
	dispUpgradeCostLabel.Parent = dispCard

	dispUpgradeButton = Instance.new("TextButton")
	dispUpgradeButton.Size = UDim2.new(0, 130, 0, 48) -- >= 44px
	dispUpgradeButton.Position = UDim2.new(1, -130, 0.5, -24)
	dispUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
	dispUpgradeButton.Font = THEME.FontBold
	dispUpgradeButton.TextSize = 15
	dispUpgradeButton.TextColor3 = THEME.TextPrimary
	dispUpgradeButton.Text = "UPGRADE"
	addCorner(dispUpgradeButton, 8)
	dispUpgradeButton.Parent = dispCard

	dispUpgradeButton.MouseButton1Click:Connect(function()
		if UIManager.OnUpgradeDisplay then
			UIManager.OnUpgradeDisplay()
		end
	end)

	-- Card 3: Walk Speed (NEW)
	local speedCard = Instance.new("Frame")
	speedCard.Name = "SpeedCard"
	speedCard.Size = UDim2.new(1, -6, 0, 115)
	speedCard.LayoutOrder = 3
	speedCard.BackgroundColor3 = THEME.Surface
	addCorner(speedCard, 10)
	addStroke(speedCard, Color3.fromRGB(0, 180, 255), 1.5)
	addPadding(speedCard, 10, 10, 12, 12)
	speedCard.Parent = shopList

	local speedCardTitle = Instance.new("TextLabel")
	speedCardTitle.Size = UDim2.new(0.65, 0, 0, 26)
	speedCardTitle.BackgroundTransparency = 1
	speedCardTitle.Font = THEME.FontBold
	speedCardTitle.TextSize = 16
	speedCardTitle.TextColor3 = Color3.fromRGB(0, 210, 255)
	speedCardTitle.TextXAlignment = Enum.TextXAlignment.Left
	speedCardTitle.Text = "⚡ Walk Speed"
	speedCardTitle.Parent = speedCard

	speedUpgradeLevelLabel = Instance.new("TextLabel")
	speedUpgradeLevelLabel.Size = UDim2.new(0.65, 0, 0, 22)
	speedUpgradeLevelLabel.Position = UDim2.new(0, 0, 0, 28)
	speedUpgradeLevelLabel.BackgroundTransparency = 1
	speedUpgradeLevelLabel.Font = THEME.FontMedium
	speedUpgradeLevelLabel.TextSize = 13
	speedUpgradeLevelLabel.TextColor3 = THEME.TextSecondary
	speedUpgradeLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedUpgradeLevelLabel.Text = "Level 0: 16 studs/s → Next: 24 studs/s"
	speedUpgradeLevelLabel.Parent = speedCard

	speedUpgradeCostLabel = Instance.new("TextLabel")
	speedUpgradeCostLabel.Size = UDim2.new(0.65, 0, 0, 24)
	speedUpgradeCostLabel.Position = UDim2.new(0, 0, 0, 52)
	speedUpgradeCostLabel.BackgroundTransparency = 1
	speedUpgradeCostLabel.Font = THEME.FontBold
	speedUpgradeCostLabel.TextSize = 15
	speedUpgradeCostLabel.TextColor3 = THEME.TextGreen
	speedUpgradeCostLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedUpgradeCostLabel.Text = "Cost: $200 Bucks"
	speedUpgradeCostLabel.Parent = speedCard

	speedUpgradeButton = Instance.new("TextButton")
	speedUpgradeButton.Size = UDim2.new(0, 130, 0, 48) -- >= 44px
	speedUpgradeButton.Position = UDim2.new(1, -130, 0.5, -24)
	speedUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
	speedUpgradeButton.Font = THEME.FontBold
	speedUpgradeButton.TextSize = 15
	speedUpgradeButton.TextColor3 = THEME.TextPrimary
	speedUpgradeButton.Text = "UPGRADE"
	addCorner(speedUpgradeButton, 8)
	speedUpgradeButton.Parent = speedCard

	speedUpgradeButton.MouseButton1Click:Connect(function()
		if UIManager.OnUpgradeSpeed then
			UIManager.OnUpgradeSpeed()
		end
	end)

	------------------------------------------------------------------
	-- 6b. ROBUX EXCLUSIVE SHOP MODAL (Robux Payment Only)
	------------------------------------------------------------------
	robuxShopModal = Instance.new("Frame")
	robuxShopModal.Name = "RobuxShopModal"
	robuxShopModal.Size = UDim2.new(0, 560, 0, 440)
	robuxShopModal.Position = UDim2.new(0.5, -280, 0.5, -220)
	robuxShopModal.BackgroundColor3 = THEME.Background
	robuxShopModal.BackgroundTransparency = 0.05
	robuxShopModal.Visible = false
	addCorner(robuxShopModal, 16)
	addStroke(robuxShopModal, Color3.fromRGB(255, 215, 0), 2)
	addPadding(robuxShopModal, 14, 14, 16, 16)
	robuxShopModal.Parent = screenGui

	-- Header
	local robuxHeader = Instance.new("Frame")
	robuxHeader.Name = "Header"
	robuxHeader.Size = UDim2.new(1, 0, 0, 48)
	robuxHeader.BackgroundTransparency = 1
	robuxHeader.Parent = robuxShopModal

	local robuxTitle = Instance.new("TextLabel")
	robuxTitle.Size = UDim2.new(0.75, 0, 0.55, 0)
	robuxTitle.BackgroundTransparency = 1
	robuxTitle.Font = THEME.FontBold
	robuxTitle.TextSize = 18
	robuxTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	robuxTitle.TextXAlignment = Enum.TextXAlignment.Left
	robuxTitle.Text = "💎 ROBUX EXCLUSIVE STORE"
	robuxTitle.Parent = robuxHeader

	local robuxSubtitle = Instance.new("TextLabel")
	robuxSubtitle.Size = UDim2.new(0.75, 0, 0.45, 0)
	robuxSubtitle.Position = UDim2.new(0, 0, 0.55, 0)
	robuxSubtitle.BackgroundTransparency = 1
	robuxSubtitle.Font = THEME.FontMedium
	robuxSubtitle.TextSize = 12
	robuxSubtitle.TextColor3 = THEME.TextSecondary
	robuxSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	robuxSubtitle.Text = "Permanent Perks & Instant Bucks (Robux Only)"
	robuxSubtitle.Parent = robuxHeader

	local robuxCloseBtn = Instance.new("TextButton")
	robuxCloseBtn.Size = UDim2.new(0, 36, 0, 36)
	robuxCloseBtn.Position = UDim2.new(1, -36, 0, 4)
	robuxCloseBtn.BackgroundColor3 = THEME.Surface
	robuxCloseBtn.Font = THEME.FontBold
	robuxCloseBtn.TextSize = 16
	robuxCloseBtn.TextColor3 = THEME.TextPrimary
	robuxCloseBtn.Text = "✕"
	addCorner(robuxCloseBtn, 8)
	addStroke(robuxCloseBtn, THEME.Stroke, 1)
	robuxCloseBtn.Parent = robuxHeader

	robuxCloseBtn.MouseButton1Click:Connect(function()
		robuxShopModal.Visible = false
	end)

	-- Scrollable Items Frame
	local robuxScroll = Instance.new("ScrollingFrame")
	robuxScroll.Name = "ProductList"
	robuxScroll.Size = UDim2.new(1, 0, 1, -56)
	robuxScroll.Position = UDim2.new(0, 0, 0, 56)
	robuxScroll.BackgroundTransparency = 1
	robuxScroll.BorderSizePixel = 0
	robuxScroll.ScrollBarThickness = 6
	robuxScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
	robuxScroll.CanvasSize = UDim2.new(0, 0, 0, 440)
	robuxScroll.Parent = robuxShopModal

	local robuxLayout = Instance.new("UIListLayout")
	robuxLayout.SortOrder = Enum.SortOrder.LayoutOrder
	robuxLayout.Padding = UDim.new(0, 8)
	robuxLayout.Parent = robuxScroll

	local robuxProducts = {
		{
			id = "VIP_PASS",
			name = "👑 VIP Gamepass",
			desc = "Permanent 2x WalkSpeed + Gold Sparkles + [VIP] Chat Tag",
			priceRobux = 249,
			icon = "👑",
			productId = 0,
			isPass = true,
		},
		{
			id = "SUPER_SPEED_COIL",
			name = "⚡ Super Speed Coil",
			desc = "Permanent +25 WalkSpeed Boost (Stacks with upgrades & items)",
			priceRobux = 149,
			icon = "⚡",
			productId = 0,
			isPass = true,
		},
		{
			id = "BUCKS_MULTIPLIER_2X",
			name = "💰 2x Bucks Multiplier",
			desc = "Double all passive Bucks earned from Display Stands forever!",
			priceRobux = 199,
			icon = "💰",
			productId = 0,
			isPass = true,
		},
		{
			id = "INFINITE_BAG",
			name = "🎒 +50 Inventory Slots",
			desc = "Expand your bag capacity by +50 slots immediately!",
			priceRobux = 99,
			icon = "🎒",
			productId = 0,
			isPass = true,
		},
		{
			id = "PACK_BUCKS_2500",
			name = "💵 2,500 Bucks Bundle",
			desc = "Instant injection of $2,500 Bucks to rush upgrades & stands",
			priceRobux = 49,
			icon = "💵",
			productId = 0,
			isPass = false,
		},
		{
			id = "PACK_BUCKS_10000",
			name = "💎 10,000 Bucks Mega-Bundle",
			desc = "Massive fortune of $10,000 Bucks for ultimate expansion",
			priceRobux = 149,
			icon = "💎",
			productId = 0,
			isPass = false,
		},
	}

	for idx, prod in ipairs(robuxProducts) do
		local card = Instance.new("Frame")
		card.Name = "Prod_" .. prod.id
		card.LayoutOrder = idx
		card.Size = UDim2.new(1, -8, 0, 64)
		card.BackgroundColor3 = THEME.Surface
		addCorner(card, 10)
		addStroke(card, Color3.fromRGB(80, 70, 40), 1)
		addPadding(card, 8, 8, 12, 12)

		-- Left icon badge
		local iconBadge = Instance.new("TextLabel")
		iconBadge.Size = UDim2.new(0, 44, 1, 0)
		iconBadge.BackgroundTransparency = 1
		iconBadge.Font = THEME.FontBold
		iconBadge.TextSize = 24
		iconBadge.Text = prod.icon
		iconBadge.Parent = card

		-- Titles
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.60, 0, 0, 22)
		nameLbl.Position = UDim2.new(0, 50, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = THEME.FontBold
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = Color3.fromRGB(255, 235, 120)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = prod.name
		nameLbl.Parent = card

		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(0.60, 0, 0, 20)
		descLbl.Position = UDim2.new(0, 50, 0, 22)
		descLbl.BackgroundTransparency = 1
		descLbl.Font = THEME.FontMedium
		descLbl.TextSize = 11
		descLbl.TextColor3 = THEME.TextSecondary
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.Text = prod.desc
		descLbl.Parent = card

		-- Robux Buy Button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 96, 0, 36)
		buyBtn.Position = UDim2.new(1, -96, 0.5, -18)
		buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		buyBtn.Font = THEME.FontBold
		buyBtn.TextSize = 13
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Text = "R$ " .. tostring(prod.priceRobux)
		addCorner(buyBtn, 8)
		addStroke(buyBtn, Color3.fromRGB(120, 255, 160), 1)
		buyBtn.Parent = card

		buyBtn.MouseButton1Click:Connect(function()
			if prod.productId and prod.productId > 0 then
				if prod.isPass then
					MarketplaceService:PromptGamePassPurchase(player, prod.productId)
				else
					MarketplaceService:PromptProductPurchase(player, prod.productId)
				end
			else
				UIManager.ShowToast("🛒 Prompting Robux Purchase for " .. prod.name .. " (R$ " .. prod.priceRobux .. ")", "Success")
			end
			if UIManager.OnRobuxPurchaseClicked then
				UIManager.OnRobuxPurchaseClicked(prod.id, prod.priceRobux)
			end
		end)

		card.Parent = robuxScroll
	end

	------------------------------------------------------------------
	-- 7. UNBOXING REVEAL MODAL
	------------------------------------------------------------------
	unboxModal = Instance.new("Frame")
	unboxModal.Name = "UnboxModal"
	unboxModal.Size = UDim2.new(1, 0, 1, 0)
	unboxModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	unboxModal.BackgroundTransparency = 0.5
	unboxModal.Visible = false
	unboxModal.Parent = screenGui

	unboxSuspenseFrame = Instance.new("Frame")
	unboxSuspenseFrame.Size = UDim2.new(0, 400, 0, 250)
	unboxSuspenseFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
	unboxSuspenseFrame.BackgroundColor3 = THEME.Background
	addCorner(unboxSuspenseFrame, 16)
	addStroke(unboxSuspenseFrame, THEME.StrokeGlow, 3)
	addPadding(unboxSuspenseFrame, 20, 20, 20, 20)
	unboxSuspenseFrame.Parent = unboxModal

	local suspenseBoxIcon = Instance.new("TextLabel")
	suspenseBoxIcon.Size = UDim2.new(1, 0, 0, 70)
	suspenseBoxIcon.BackgroundTransparency = 1
	suspenseBoxIcon.Font = THEME.FontBold
	suspenseBoxIcon.TextSize = 48
	suspenseBoxIcon.Text = "🎁"
	suspenseBoxIcon.Parent = unboxSuspenseFrame

	unboxSuspenseText = Instance.new("TextLabel")
	unboxSuspenseText.Size = UDim2.new(1, 0, 0, 40)
	unboxSuspenseText.Position = UDim2.new(0, 0, 0, 80)
	unboxSuspenseText.BackgroundTransparency = 1
	unboxSuspenseText.Font = THEME.FontBold
	unboxSuspenseText.TextSize = 16
	unboxSuspenseText.TextColor3 = THEME.TextPrimary
	unboxSuspenseText.Text = "OPENING MYSTERY BOX..."
	unboxSuspenseText.Parent = unboxSuspenseFrame

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 16)
	barBg.Position = UDim2.new(0, 0, 1, -26)
	barBg.BackgroundColor3 = THEME.Surface
	addCorner(barBg, 8)
	barBg.Parent = unboxSuspenseFrame

	unboxProgressBar = Instance.new("Frame")
	unboxProgressBar.Size = UDim2.new(0, 0, 1, 0)
	unboxProgressBar.BackgroundColor3 = THEME.ButtonPrimary
	addCorner(unboxProgressBar, 8)
	unboxProgressBar.Parent = barBg

	unboxRevealFrame = Instance.new("Frame")
	unboxRevealFrame.Size = UDim2.new(0, 420, 0, 340)
	unboxRevealFrame.Position = UDim2.new(0.5, -210, 0.5, -170)
	unboxRevealFrame.BackgroundColor3 = THEME.Background
	unboxRevealFrame.Visible = false
	addCorner(unboxRevealFrame, 16)
	addStroke(unboxRevealFrame, THEME.TextGold, 3)
	addPadding(unboxRevealFrame, 20, 20, 20, 20)
	unboxRevealFrame.Parent = unboxModal

	unboxRarityBadge = Instance.new("TextLabel")
	unboxRarityBadge.Size = UDim2.new(1, 0, 0, 32)
	unboxRarityBadge.BackgroundTransparency = 1
	unboxRarityBadge.Font = THEME.FontBold
	unboxRarityBadge.TextSize = 18
	unboxRarityBadge.TextColor3 = THEME.TextGold
	unboxRarityBadge.Text = "★ LEGENDARY REVEAL ★"
	unboxRarityBadge.Parent = unboxRevealFrame

	unboxItemName = Instance.new("TextLabel")
	unboxItemName.Size = UDim2.new(1, 0, 0, 48)
	unboxItemName.Position = UDim2.new(0, 0, 0, 40)
	unboxItemName.BackgroundTransparency = 1
	unboxItemName.Font = THEME.FontBold
	unboxItemName.TextSize = 24
	unboxItemName.TextColor3 = THEME.TextPrimary
	unboxItemName.Text = "Cyberpunk DJ"
	unboxItemName.Parent = unboxRevealFrame

	unboxBiomeLabel = Instance.new("TextLabel")
	unboxBiomeLabel.Size = UDim2.new(1, 0, 0, 24)
	unboxBiomeLabel.Position = UDim2.new(0, 0, 0, 92)
	unboxBiomeLabel.BackgroundTransparency = 1
	unboxBiomeLabel.Font = THEME.FontMedium
	unboxBiomeLabel.TextSize = 14
	unboxBiomeLabel.TextColor3 = THEME.TextSecondary
	unboxBiomeLabel.Text = "Biome: Urban"
	unboxBiomeLabel.Parent = unboxRevealFrame

	unboxIncomeLabel = Instance.new("TextLabel")
	unboxIncomeLabel.Size = UDim2.new(1, 0, 0, 36)
	unboxIncomeLabel.Position = UDim2.new(0, 0, 0, 124)
	unboxIncomeLabel.BackgroundTransparency = 1
	unboxIncomeLabel.Font = THEME.FontBold
	unboxIncomeLabel.TextSize = 20
	unboxIncomeLabel.TextColor3 = THEME.TextGreen
	unboxIncomeLabel.Text = "+$100 / sec on Display Stand"
	unboxIncomeLabel.Parent = unboxRevealFrame

	unboxClaimBtn = Instance.new("TextButton")
	unboxClaimBtn.Size = UDim2.new(1, 0, 0, 52) -- >= 44px
	unboxClaimBtn.Position = UDim2.new(0, 0, 1, -52)
	unboxClaimBtn.BackgroundColor3 = THEME.ButtonSuccess
	unboxClaimBtn.Font = THEME.FontBold
	unboxClaimBtn.TextSize = 18
	unboxClaimBtn.TextColor3 = THEME.TextPrimary
	unboxClaimBtn.Text = "COLLECT TO INVENTORY"
	addCorner(unboxClaimBtn, 10)
	unboxClaimBtn.Parent = unboxRevealFrame

	unboxClaimBtn.MouseButton1Click:Connect(function()
		unboxModal.Visible = false
		unboxRevealFrame.Visible = false
		if UIManager.OnUnboxClaimClicked then
			UIManager.OnUnboxClaimClicked()
		end
	end)

	------------------------------------------------------------------
	-- 8. TOP TOAST NOTIFICATION BANNER (Compact & Non-intrusive)
	------------------------------------------------------------------
	toastContainer = Instance.new("Frame")
	toastContainer.Name = "ToastContainer"
	toastContainer.Size = UDim2.new(0, 360, 0, 36)
	toastContainer.Position = UDim2.new(0.5, -180, 0, -50)
	toastContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	toastContainer.BackgroundTransparency = 0.1
	toastContainer.Visible = false
	addCorner(toastContainer, 8)
	addStroke(toastContainer, THEME.StrokeGlow, 1.5)
	addPadding(toastContainer, 4, 4, 10, 10)
	toastContainer.Parent = screenGui

	toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, 0, 1, 0)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Font = THEME.FontBold
	toastLabel.TextSize = 12
	toastLabel.TextColor3 = THEME.TextPrimary
	toastLabel.Text = "Welcome to Steal a Mystery Box!"
	toastLabel.Parent = toastContainer

	-- Live Waypoint compass update loop
	task.spawn(function()
		while true do
			task.wait(0.5)
			local char = player.Character
			local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if hrp and waypointLabel then
				if currentWaypointTarget then
					local dist = math.floor((hrp.Position - currentWaypointTarget).Magnitude)
					waypointLabel.Text = "🎯 " .. currentWaypointName .. " (" .. tostring(dist) .. " studs)"
					waypointLabel.TextColor3 = THEME.TextGold
				else
					-- Check which zone player is in
					local x = hrp.Position.X
					local z = hrp.Position.Z
					if math.sqrt(x*x + z*z) < 70 then
						local p = player:GetAttribute("AssignedPlot")
						waypointLabel.Text = "🛡️ SAFEZONE HUB · " .. (if typeof(p) == "string" then ("🏡 " .. p) else "Plots Ring")
						waypointLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
					elseif x < -50 and z > 50 then
						waypointLabel.Text = "🏙️ URBAN · City Streets"
						waypointLabel.TextColor3 = Color3.fromRGB(40, 150, 255)
					elseif x < -50 and z < -50 then
						waypointLabel.Text = "🏚️ SLUMS · Backstreets & Scrap"
						waypointLabel.TextColor3 = Color3.fromRGB(220, 110, 40)
					elseif z > 70 and math.abs(x) < 60 then
						waypointLabel.Text = "🏔️ MOUNTAIN GATEWAY"
						waypointLabel.TextColor3 = Color3.fromRGB(46, 140, 80)
					else
						waypointLabel.Text = "🧭 WORLD HIGHWAY"
						waypointLabel.TextColor3 = THEME.TextSecondary
					end
				end
			end
		end
	end)

	print("[UIManager] Programmatic UI Generated with Hub-and-Spoke Map.")
end

----------------------------------------------------------------------
-- Public UI Methods
----------------------------------------------------------------------

function UIManager.IsAnyModalOpen(): boolean
	local mapOpen = worldMapModal and worldMapModal.Visible
	local invOpen = inventoryModal and inventoryModal.Visible
	local shopOpen = shopModal and shopModal.Visible
	local robuxOpen = robuxShopModal and robuxShopModal.Visible
	local unboxOpen = unboxModal and unboxModal.Visible
	return (mapOpen or invOpen or shopOpen or robuxOpen or unboxOpen) == true
end

function UIManager.CloseAllModals()
	if worldMapModal then worldMapModal.Visible = false end
	if inventoryModal then inventoryModal.Visible = false end
	if shopModal then shopModal.Visible = false end
	if robuxShopModal then robuxShopModal.Visible = false end
	if unboxModal then unboxModal.Visible = false end
end

function UIManager.ToggleRobuxShop(visible: boolean?)
	if not robuxShopModal then return end
	if visible ~= nil then
		robuxShopModal.Visible = visible
	else
		robuxShopModal.Visible = not robuxShopModal.Visible
	end
end

function UIManager.ToggleMap(visible: boolean?)
	if not worldMapModal then return end
	if visible ~= nil then
		worldMapModal.Visible = visible
	else
		worldMapModal.Visible = not worldMapModal.Visible
	end
end

function UIManager.ToggleInventory(visible: boolean?)
	if not inventoryModal then return end
	if visible ~= nil then
		inventoryModal.Visible = visible
	else
		inventoryModal.Visible = not inventoryModal.Visible
	end
	if inventoryModal.Visible and UIManager.RefreshInventoryUI then
		UIManager.RefreshInventoryUI()
	end
end

function UIManager.ToggleShop(visible: boolean?)
	if not shopModal then return end
	if visible ~= nil then
		shopModal.Visible = visible
	else
		shopModal.Visible = not shopModal.Visible
	end
end

function UIManager.UpdateEconomy(bucks: number, pendingBucks: number, incomeRate: number)
	if not bucksLabel then return end
	bucksLabel.Text = "💵 $" .. tostring(bucks) .. " Bucks"
	pendingLabel.Text = "⏳ Pending: +$" .. tostring(pendingBucks) .. " (+$" .. tostring(incomeRate) .. "/s)"
	if claimButton then
		if pendingBucks > 0 then
			claimButton.Text = if isDesktop then ("CLAIM +$" .. tostring(pendingBucks) .. " [C]") else ("CLAIM +$" .. tostring(pendingBucks))
			claimButton.BackgroundColor3 = THEME.ButtonSuccess
		else
			claimButton.Text = if isDesktop then "CLAIM [C]" else "CLAIM"
			claimButton.BackgroundColor3 = THEME.ButtonDisabled
		end
	end
	if shopBucksLabel then
		shopBucksLabel.Text = "Wallet: $" .. tostring(bucks)
	end
end

function UIManager.UpdateCarriedBox(boxInfo: { boxTypeId: string, biomeId: string }?)
	if not boxLabel or not boxBadge then return end
	if boxInfo then
		local boxDef = BoxesConfig.GetBox(boxInfo.boxTypeId)
		local boxDisplayName = if boxDef then boxDef.displayName else (boxInfo.biomeId .. " Mystery Box")
		local boxColor = if boxDef then boxDef.themeColor else Color3.fromRGB(255, 120, 80)

		boxLabel.Text = "🚨 " .. string.upper(boxDisplayName) .. " · RUN TO SAFEZONE! 🚨"
		boxLabel.TextColor3 = boxColor
		local stroke = boxBadge:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = boxColor
		end
		boxBadge.Visible = true

		-- Set waypoint to player's plot automatically when carrying box!
		local assignedPlot = player:GetAttribute("AssignedPlot")
		if typeof(assignedPlot) == "string" then
			local plotsFolder = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PlayerPlots")
			local plotModel = plotsFolder and plotsFolder:FindFirstChild(assignedPlot)
			if plotModel and plotModel.PrimaryPart then
				currentWaypointTarget = plotModel.PrimaryPart.Position
				currentWaypointName = "My Plot (Unbox Here!)"
			end
		end
	else
		boxBadge.Visible = false
		if currentWaypointName == "My Plot (Unbox Here!)" then
			currentWaypointTarget = nil
			currentWaypointName = "None"
		end
	end
end

function UIManager.UpdatePlot(plotId: string?)
	if not plotLabel then return end
	if plotId then
		plotLabel.Text = "🏡 " .. plotId
		plotLabel.TextColor3 = THEME.TextGold
	else
		plotLabel.Text = "🏡 No Plot"
		plotLabel.TextColor3 = THEME.TextSecondary
	end
end

function UIManager.UpdateUpgrades(
	invLevel: number, invMax: number, invNextCost: number,
	dispLevel: number, dispMax: number, dispNextCost: number,
	speedLevel: number?, speedVal: number?, speedNextCost: number?, speedNextVal: number?
)
	if not invUpgradeLevelLabel then return end

	-- Inventory Capacity Card
	if invLevel >= 3 then
		invUpgradeLevelLabel.Text = "Level " .. invLevel .. " (MAX): " .. invMax .. " slots"
		invUpgradeCostLabel.Text = "MAX LEVEL REACHED"
		invUpgradeButton.Text = "MAXED"
		invUpgradeButton.BackgroundColor3 = THEME.ButtonDisabled
	else
		invUpgradeLevelLabel.Text = "Level " .. invLevel .. ": " .. invMax .. " slots"
		invUpgradeCostLabel.Text = "Next Level Cost: $" .. invNextCost .. " Bucks"
		invUpgradeButton.Text = "UPGRADE"
		invUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
	end

	-- Display Stand Capacity Card
	if dispLevel >= 3 then
		dispUpgradeLevelLabel.Text = "Level " .. dispLevel .. " (MAX): " .. dispMax .. " stands"
		dispUpgradeCostLabel.Text = "MAX LEVEL REACHED"
		dispUpgradeButton.Text = "MAXED"
		dispUpgradeButton.BackgroundColor3 = THEME.ButtonDisabled
	else
		dispUpgradeLevelLabel.Text = "Level " .. dispLevel .. ": " .. dispMax .. " stands"
		dispUpgradeCostLabel.Text = "Next Level Cost: $" .. dispNextCost .. " Bucks"
		dispUpgradeButton.Text = "UPGRADE"
		dispUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
	end

	-- Walk Speed Card (NEW)
	if speedUpgradeLevelLabel and speedLevel ~= nil and speedVal ~= nil then
		if speedLevel >= 3 then
			speedUpgradeLevelLabel.Text = "Level " .. speedLevel .. " (MAX): " .. speedVal .. " studs/s"
			speedUpgradeCostLabel.Text = "MAX LEVEL REACHED"
			speedUpgradeButton.Text = "MAXED"
			speedUpgradeButton.BackgroundColor3 = THEME.ButtonDisabled
		else
			local nextVal = speedNextVal or (speedVal + 8)
			speedUpgradeLevelLabel.Text = "Level " .. speedLevel .. ": " .. speedVal .. " studs/s → Next: " .. nextVal .. " studs/s"
			speedUpgradeCostLabel.Text = "Next Level Cost: $" .. (speedNextCost or 0) .. " Bucks"
			speedUpgradeButton.Text = "UPGRADE"
			speedUpgradeButton.BackgroundColor3 = THEME.ButtonSuccess
		end
	end
end

function UIManager.UpdateSpeedometer(actualSpeed: number, baseSpeed: number, isSlowed: boolean, level: number?)
	if not speedometerContainer or not speedometerValueLabel then return end

	local speedStr = string.format("%.1f", actualSpeed)
	speedometerValueLabel.Text = "⚡ " .. speedStr .. " studs/s"

	local fillRatio = math.clamp(actualSpeed / 50, 0.05, 1)
	speedometerBar.Size = UDim2.new(fillRatio, 0, 1, 0)

	local stroke = speedometerContainer:FindFirstChildOfClass("UIStroke")

	if isSlowed then
		speedometerValueLabel.TextColor3 = Color3.fromRGB(255, 175, 50)
		speedometerStatusLabel.Text = "⚠️ SLOWED (80%)"
		speedometerStatusLabel.TextColor3 = Color3.fromRGB(255, 175, 50)
		speedometerBar.BackgroundColor3 = Color3.fromRGB(255, 175, 50)
		if stroke then stroke.Color = Color3.fromRGB(255, 175, 50) end
	else
		local color = Color3.fromRGB(0, 220, 255)
		if actualSpeed >= 50 then
			color = Color3.fromRGB(255, 215, 0) -- Gold for max speed!
		end
		speedometerValueLabel.TextColor3 = color
		local lvlText = if level ~= nil then ("LVL " .. tostring(level)) else "SPRINT"
		speedometerStatusLabel.Text = "⚡ " .. lvlText
		speedometerStatusLabel.TextColor3 = THEME.TextSecondary
		speedometerBar.BackgroundColor3 = color
		if stroke then stroke.Color = THEME.Stroke end
	end
end

function UIManager.PopulateInventory(items: { { instanceId: string, itemId: string, name: string, biomeId: string, rarity: string, incomePerSecond: number, speedBoost: number?, isDisplayed: boolean, isEquipped: boolean?, standId: number? } }, capacity: number)
	if not inventoryGrid then return end

	inventoryCapacityLabel.Text = "Capacity: " .. tostring(#items) .. " / " .. tostring(capacity)
	local invBtnPrefix = if isDesktop then "🎒 Bag [E] (" else "🎒 Bag ("
	if inventoryButton then
		inventoryButton.Text = invBtnPrefix .. tostring(#items) .. "/" .. tostring(capacity) .. ")"
	end

	for _, child in inventoryGrid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local count = 0
	for _, item in ipairs(items) do
		if inventoryFilter == "Urban" and item.biomeId ~= "Urban" then
			continue
		elseif inventoryFilter == "Slums" and item.biomeId ~= "Slums" then
			continue
		elseif inventoryFilter == "Rare+" and (item.rarity == "Common" or item.rarity == "Uncommon") then
			continue
		end

		count += 1
		local rarityColor = RARITY_COLORS[item.rarity] or THEME.TextPrimary
		local speedBoost = item.speedBoost or 2

		local card = Instance.new("Frame")
		card.Name = "ItemCard_" .. item.instanceId
		card.BackgroundColor3 = THEME.Surface
		addCorner(card, 8)
		addStroke(card, rarityColor, 1.5)
		addPadding(card, 6, 6, 8, 8)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = THEME.FontBold
		nameLabel.TextSize = 13
		nameLabel.TextColor3 = rarityColor
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Text = item.name
		nameLabel.Parent = card

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(1, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 0, 0, 22)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Font = THEME.FontMedium
		statsLabel.TextSize = 11
		statsLabel.TextColor3 = THEME.TextGreen
		statsLabel.Text = "+$" .. tostring(item.incomePerSecond) .. "/s | ⚡ +" .. tostring(speedBoost) .. " Speed"
		statsLabel.Parent = card

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(1, 0, 0, 18)
		statusLabel.Position = UDim2.new(0, 0, 0, 42)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Font = THEME.FontBold
		statusLabel.TextSize = 11
		if item.isEquipped then
			statusLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
			statusLabel.Text = "⚡ EQUIPPED ACCESSORY"
		elseif item.isDisplayed then
			statusLabel.TextColor3 = THEME.TextGold
			statusLabel.Text = "🏛️ On Stand #" .. tostring(item.standId or 1)
		else
			statusLabel.TextColor3 = THEME.TextSecondary
			statusLabel.Text = "In Bag"
		end
		statusLabel.Parent = card

		-- Left Button: Equip / Unequip Accessory
		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0.48, 0, 0, 36)
		equipBtn.Position = UDim2.new(0, 0, 1, -38)
		equipBtn.BackgroundColor3 = item.isEquipped and THEME.ButtonDanger or Color3.fromRGB(0, 160, 220)
		equipBtn.Font = THEME.FontBold
		equipBtn.TextSize = 10
		equipBtn.TextColor3 = THEME.TextPrimary
		equipBtn.Text = item.isEquipped and "UNEQUIP" or "EQUIP ⚡"
		addCorner(equipBtn, 6)
		equipBtn.Parent = card

		equipBtn.MouseButton1Click:Connect(function()
			if UIManager.OnItemActionClicked then
				local action = item.isEquipped and "Unequip" or "Equip"
				UIManager.OnItemActionClicked(item.instanceId, action)
			end
		end)

		-- Right Button: Place on Stand / Remove from Stand
		local standBtn = Instance.new("TextButton")
		standBtn.Size = UDim2.new(0.48, 0, 0, 36)
		standBtn.Position = UDim2.new(0.52, 0, 1, -38)
		standBtn.BackgroundColor3 = item.isDisplayed and THEME.ButtonDanger or THEME.ButtonPrimary
		standBtn.Font = THEME.FontBold
		standBtn.TextSize = 10
		standBtn.TextColor3 = THEME.TextPrimary
		standBtn.Text = item.isDisplayed and "REMOVE" or "STAND"
		addCorner(standBtn, 6)
		standBtn.Parent = card

		standBtn.MouseButton1Click:Connect(function()
			if UIManager.OnItemActionClicked then
				local action = item.isDisplayed and "Remove" or "Place"
				UIManager.OnItemActionClicked(item.instanceId, action)
			end
		end)

		card.Parent = inventoryGrid
	end

	local rows = math.ceil(count / 3)
	inventoryGrid.CanvasSize = UDim2.new(0, 0, 0, rows * 160)
end

function UIManager.PlayUnboxSequence(boxInfo: { boxTypeId: string, biomeId: string }, itemInfo: { name: string, rarity: string, biomeId: string, incomePerSecond: number })
	if not unboxModal then return end

	local rarityColor = RARITY_COLORS[itemInfo.rarity] or THEME.TextGold
	local boxDef = BoxesConfig.GetBox(boxInfo.boxTypeId)
	local boxName = if boxDef then boxDef.displayName else (boxInfo.biomeId .. " Mystery Box")

	unboxModal.Visible = true
	unboxSuspenseFrame.Visible = true
	unboxRevealFrame.Visible = false

	unboxSuspenseText.Text = "OPENING " .. string.upper(boxName) .. "..."
	unboxProgressBar.Size = UDim2.new(0, 0, 1, 0)

	local tween = TweenService:Create(unboxProgressBar, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0)
	})
	tween:Play()

	task.delay(2.1, function()
		unboxSuspenseFrame.Visible = false
		unboxRevealFrame.Visible = true

		unboxRarityBadge.Text = "★ " .. string.upper(itemInfo.rarity) .. " REVEAL ★"
		unboxRarityBadge.TextColor3 = rarityColor
		unboxItemName.Text = itemInfo.name
		unboxBiomeLabel.Text = "Biome: " .. itemInfo.biomeId .. " (" .. itemInfo.rarity .. " Drop)"
		unboxIncomeLabel.Text = "+$" .. tostring(itemInfo.incomePerSecond) .. "/s Passive Income"

		local stroke = unboxRevealFrame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = rarityColor
		end
	end)
end

function UIManager.ShowToast(message: string, alertType: string?)
	if not toastContainer or not toastLabel then return end

	local color = THEME.StrokeGlow
	if alertType == "Error" then
		color = THEME.ButtonDanger
	elseif alertType == "Success" then
		color = THEME.ButtonSuccess
	elseif alertType == "Warning" then
		color = THEME.ButtonWarning
	end

	local stroke = toastContainer:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end

	toastLabel.Text = message
	toastContainer.Visible = true
	toastContainer.Position = UDim2.new(0.5, -180, 0, -50)

	local slideDown = TweenService:Create(toastContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -180, 0, 14)
	})
	slideDown:Play()

	task.delay(2.5, function()
		local slideUp = TweenService:Create(toastContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -180, 0, -50)
		})
		slideUp:Play()
		slideUp.Completed:Connect(function()
			toastContainer.Visible = false
		end)
	end)
end

return UIManager	 
