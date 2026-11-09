--!strict
--[[
	PlotService — Manages player plot assignment, ownership, and physical plot geometry.
	Authority: GDD §4, §11 (AC-01) & WorldMapV1.png (Hub-and-Spoke Layout).
	
	Features:
	  - Circular Safezone Hub with 8 radial player plots around central Player Spawn
	  - Replicates assigned plot to client attribute player:SetAttribute("AssignedPlot", plotId)
	  - Clean plot assignment on join and release on leave
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlotService = {}

export type PlotRecord = {
	plotId: string,
	ownerId: number?,
	isOccupied: boolean,
	model: Model?,
}

local MAX_PLOTS = 8
local plots: { PlotRecord } = {}
local playerPlotMap: { [number]: string } = {}

local function getSafezoneFolder(): Folder
	local world = Workspace:FindFirstChild("World")
	if not world then
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end

	local safezone = world:FindFirstChild("Safezone")
	if not safezone then
		safezone = Instance.new("Folder")
		safezone.Name = "Safezone"
		safezone.Parent = world
	end
	return safezone :: Folder
end

local function getPlotsFolder(): Folder
	local world = Workspace:FindFirstChild("World")
	if not world then
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end

	local plotsFolder = world:FindFirstChild("PlayerPlots")
	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "PlayerPlots"
		plotsFolder.Parent = world
	end
	return plotsFolder :: Folder
end

--[[
	Builds the central Player Spawn Plaza in Safezone.
]]
local function buildCenterPlaza(safezoneFolder: Folder)
	local existing = safezoneFolder:FindFirstChild("CentralSpawnPlaza")
	if existing then return end

	local plazaModel = Instance.new("Model")
	plazaModel.Name = "CentralSpawnPlaza"

	-- Main Plaza Floor (Center Hub)
	local plaza = Instance.new("Part")
	plaza.Name = "PlazaGround"
	plaza.Shape = Enum.PartType.Cylinder
	plaza.Size = Vector3.new(1.2, 50, 50)
	plaza.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	plaza.Anchored = true
	plaza.Material = Enum.Material.SmoothPlastic
	plaza.Color = Color3.fromRGB(45, 52, 70)
	plaza.TopSurface = Enum.SurfaceType.Smooth
	plaza.Parent = plazaModel

	-- Central SpawnLocation
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "CenterSpawn"
	spawnLoc.Size = Vector3.new(16, 0.5, 16)
	spawnLoc.Position = Vector3.new(0, 0.85, 0)
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.Color = Color3.fromRGB(0, 180, 240)
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = plazaModel

	-- Center Monument / Beacon
	local beacon = Instance.new("Part")
	beacon.Name = "CenterBeacon"
	beacon.Size = Vector3.new(3, 10, 3)
	beacon.Position = Vector3.new(0, 6, 0)
	beacon.Anchored = true
	beacon.Material = Enum.Material.Neon
	beacon.Color = Color3.fromRGB(255, 205, 50)
	beacon.CanCollide = false
	beacon.Parent = plazaModel

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BeaconBillboard"
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = beacon
	billboard.Parent = beacon

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	label.BackgroundTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextColor3 = Color3.fromRGB(255, 205, 50)
	label.Text = "⭐ SAFEZONE SPAWN PLAZA\n8 Player Plots Ring"
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	label.Parent = billboard

	plazaModel.Parent = safezoneFolder
end

--[[
	Builds physical geometry for one plot in the radial ring (Hub-and-Spoke).
]]
local function buildPhysicalPlot(plotId: string, index: number, folder: Folder): Model
	local existing = folder:FindFirstChild(plotId)
	if existing and existing:IsA("Model") then
		return existing
	end

	local plotModel = Instance.new("Model")
	plotModel.Name = plotId

	-- Radial Hub-and-Spoke calculation matching WorldMapV1.png
	local angle = (index - 1) * (2 * math.pi / MAX_PLOTS)
	local radius = 64
	local originX = math.cos(angle) * radius
	local originZ = math.sin(angle) * radius

	-- Ground Basepart
	local ground = Instance.new("Part")
	ground.Name = "PlotGround"
	ground.Size = Vector3.new(34, 1, 34)
	ground.Position = Vector3.new(originX, 0.5, originZ)
	ground.Anchored = true
	ground.Material = Enum.Material.SmoothPlastic
	ground.Color = Color3.fromRGB(32, 38, 52)
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = plotModel

	-- Sign / Billboard
	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(1, 6, 1)
	signPost.Position = Vector3.new(originX - 14, 3.5, originZ + 14)
	signPost.Anchored = true
	signPost.Color = Color3.fromRGB(75, 82, 100)
	signPost.Parent = plotModel

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlotBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = signPost
	billboard.Parent = signPost

	local signLabel = Instance.new("TextLabel")
	signLabel.Name = "SignLabel"
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundColor3 = Color3.fromRGB(20, 23, 34)
	signLabel.BackgroundTransparency = 0.2
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextSize = 16
	signLabel.TextColor3 = Color3.fromRGB(255, 205, 50)
	signLabel.Text = "[" .. plotId .. "]\nVacant Plot"
	local signCorner = Instance.new("UICorner")
	signCorner.CornerRadius = UDim.new(0, 8)
	signCorner.Parent = signLabel
	signLabel.Parent = billboard

	-- Unbox Pad (Uses [F] to unbox)
	local unboxPad = Instance.new("Part")
	unboxPad.Name = "UnboxPad"
	unboxPad.Size = Vector3.new(7, 1, 7)
	unboxPad.Position = Vector3.new(originX, 0.6, originZ - 8)
	unboxPad.Anchored = true
	unboxPad.Material = Enum.Material.Neon
	unboxPad.Color = Color3.fromRGB(0, 200, 255)
	unboxPad:SetAttribute("PlotId", plotId)
	unboxPad.Parent = plotModel

	local unboxBillboard = Instance.new("BillboardGui")
	unboxBillboard.Name = "UnboxBillboard"
	unboxBillboard.Size = UDim2.new(0, 160, 0, 40)
	unboxBillboard.StudsOffset = Vector3.new(0, 3, 0)
	unboxBillboard.Adornee = unboxPad
	unboxBillboard.Parent = unboxPad

	local unboxLabel = Instance.new("TextLabel")
	unboxLabel.Name = "UnboxLabel"
	unboxLabel.Size = UDim2.new(1, 0, 1, 0)
	unboxLabel.BackgroundColor3 = Color3.fromRGB(20, 23, 34)
	unboxLabel.BackgroundTransparency = 0.25
	unboxLabel.Font = Enum.Font.GothamBold
	unboxLabel.TextSize = 13
	unboxLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	unboxLabel.Text = "📦 UNBOX PAD\nHold [F] to Unbox"
	local unboxCorner = Instance.new("UICorner")
	unboxCorner.CornerRadius = UDim.new(0, 6)
	unboxCorner.Parent = unboxLabel
	unboxLabel.Parent = unboxBillboard

	local unboxPrompt = Instance.new("ProximityPrompt")
	unboxPrompt.ActionText = "Unbox"
	unboxPrompt.ObjectText = "Hold [F] to Unbox"
	unboxPrompt.KeyboardKeyCode = Enum.KeyCode.F -- Differentiated from [E] Inventory
	unboxPrompt.HoldDuration = 0.5
	unboxPrompt.MaxActivationDistance = 10
	unboxPrompt.RequiresLineOfSight = false
	unboxPrompt:SetAttribute("PromptType", "UnboxPad")
	unboxPrompt.Parent = unboxPad

	-- Money Collector (Uses [F] or [C] on keyboard)
	local collector = Instance.new("Part")
	collector.Name = "MoneyCollector"
	collector.Size = Vector3.new(4, 5, 4)
	collector.Position = Vector3.new(originX + 11, 3, originZ + 11)
	collector.Anchored = true
	collector.Material = Enum.Material.SmoothPlastic
	collector.Color = Color3.fromRGB(255, 195, 45)
	collector:SetAttribute("PlotId", plotId)
	collector.Parent = plotModel

	local collectorPrompt = Instance.new("ProximityPrompt")
	collectorPrompt.ActionText = "Claim Bucks"
	collectorPrompt.ObjectText = "Press [F] or [C]"
	collectorPrompt.KeyboardKeyCode = Enum.KeyCode.F
	collectorPrompt.HoldDuration = 0.2
	collectorPrompt.MaxActivationDistance = 10
	collectorPrompt.RequiresLineOfSight = false
	collectorPrompt:SetAttribute("PromptType", "MoneyCollector")
	collectorPrompt.Parent = collector

	-- 3 Starting Display Stands
	for s = 1, 3 do
		local stand = Instance.new("Part")
		stand.Name = "Stand_" .. tostring(s)
		stand.Size = Vector3.new(4, 2.5, 4)
		local standX = originX - 9 + (s - 1) * 9
		local standZ = originZ + 5
		stand.Position = Vector3.new(standX, 1.8, standZ)
		stand.Anchored = true
		stand.Material = Enum.Material.SmoothPlastic
		stand.Color = Color3.fromRGB(60, 68, 88)
		stand:SetAttribute("PlotId", plotId)
		stand:SetAttribute("StandId", s)
		stand.Parent = plotModel

		local standBillboard = Instance.new("BillboardGui")
		standBillboard.Name = "StandBillboard"
		standBillboard.Size = UDim2.new(0, 140, 0, 40)
		standBillboard.StudsOffset = Vector3.new(0, 3, 0)
		standBillboard.Adornee = stand
		standBillboard.Parent = stand

		local standLabel = Instance.new("TextLabel")
		standLabel.Name = "StandLabel"
		standLabel.Size = UDim2.new(1, 0, 1, 0)
		standLabel.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
		standLabel.BackgroundTransparency = 0.3
		standLabel.Font = Enum.Font.GothamMedium
		standLabel.TextSize = 12
		standLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
		standLabel.Text = "Stand #" .. s .. "\n(Empty)"
		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 6)
		sc.Parent = standLabel
		standLabel.Parent = standBillboard
	end

	plotModel.PrimaryPart = ground
	plotModel.Parent = folder
	return plotModel
end

local function findFreePlot(): PlotRecord?
	for _, plot in plots do
		if not plot.isOccupied then
			return plot
		end
	end
	return nil
end

local function getPlotById(plotId: string): PlotRecord?
	for _, plot in plots do
		if plot.plotId == plotId then
			return plot
		end
	end
	return nil
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function PlotService.Init()
	local safezoneFolder = getSafezoneFolder()
	buildCenterPlaza(safezoneFolder)

	local folder = getPlotsFolder()
	for i = 1, MAX_PLOTS do
		local plotId = "Plot_" .. tostring(i)
		local model = buildPhysicalPlot(plotId, i, folder)
		table.insert(plots, {
			plotId = plotId,
			ownerId = nil,
			isOccupied = false,
			model = model,
		})
	end
	print("[PlotService] Initialized " .. tostring(MAX_PLOTS) .. " plots in Hub-and-Spoke circular ring.")
end

function PlotService.Start()
	print("[PlotService] Started.")
end

function PlotService.OnPlayerAdded(player: Player)
	local userId = player.UserId

	if playerPlotMap[userId] then
		warn("[PlotService] Player " .. player.Name .. " already assigned plot " .. playerPlotMap[userId])
		return
	end

	local freePlot = findFreePlot()
	if not freePlot then
		warn("[PlotService] No free plots for " .. player.Name .. "! Max plots = " .. tostring(MAX_PLOTS))
		return
	end

	freePlot.ownerId = userId
	freePlot.isOccupied = true
	playerPlotMap[userId] = freePlot.plotId

	-- Set player attribute for client replication
	player:SetAttribute("AssignedPlot", freePlot.plotId)

	-- Update physical sign
	if freePlot.model then
		local signPost = freePlot.model:FindFirstChild("SignPost")
		if signPost then
			local billboard = signPost:FindFirstChild("PlotBillboard")
			if billboard then
				local label = billboard:FindFirstChild("SignLabel") :: TextLabel?
				if label then
					label.Text = "[" .. freePlot.plotId .. "]\nOwner: " .. player.DisplayName
					label.TextColor3 = Color3.fromRGB(80, 230, 130)
				end
			end
		end
	end

	print("[PlotService] Assigned " .. freePlot.plotId .. " to " .. player.Name .. " (UserId: " .. tostring(userId) .. ")")
end

function PlotService.OnPlayerRemoving(player: Player)
	local userId = player.UserId
	local plotId = playerPlotMap[userId]

	if not plotId then return end

	local plot = getPlotById(plotId)
	if plot then
		plot.ownerId = nil
		plot.isOccupied = false

		-- Reset physical sign
		if plot.model then
			local signPost = plot.model:FindFirstChild("SignPost")
			if signPost then
				local billboard = signPost:FindFirstChild("PlotBillboard")
				if billboard then
					local label = billboard:FindFirstChild("SignLabel") :: TextLabel?
					if label then
						label.Text = "[" .. plot.plotId .. "]\nVacant Plot"
						label.TextColor3 = Color3.fromRGB(255, 205, 50)
					end
				end
			end
		end

		print("[PlotService] Released " .. plotId .. " from " .. player.Name)
	end

	playerPlotMap[userId] = nil
	player:SetAttribute("AssignedPlot", nil)
end

function PlotService.GetPlotForPlayer(player: Player): string?
	return playerPlotMap[player.UserId]
end

function PlotService.GetPlotOwner(plotId: string): Player?
	local plot = getPlotById(plotId)
	if not plot or not plot.ownerId then return nil end
	return Players:GetPlayerByUserId(plot.ownerId)
end

function PlotService.IsPlotOwner(player: Player, plotId: string): boolean
	local assignedPlot = playerPlotMap[player.UserId]
	return assignedPlot ~= nil and assignedPlot == plotId
end

function PlotService.GetPlotRecord(plotId: string): PlotRecord?
	return getPlotById(plotId)
end

function PlotService.GetAllPlots(): { PlotRecord }
	local copy: { PlotRecord } = {}
	for _, plot in plots do
		table.insert(copy, {
			plotId = plot.plotId,
			ownerId = plot.ownerId,
			isOccupied = plot.isOccupied,
		})
	end
	return copy
end

return PlotService
