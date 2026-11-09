--!strict
--[[
	Main Server Bootstrap — Steal a Mystery Box!
	
	Initializes Network and all server services in dependency order,
	then starts them and connects player lifecycle events.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 0. Initialize Network Remotes first
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Network = require(sharedFolder:WaitForChild("Network") :: ModuleScript)
Network.InitServer()

-- Require all services with WaitForChild to eliminate race conditions
local Services = ServerScriptService:WaitForChild("Services")

local DataService      = require(Services:WaitForChild("DataService") :: ModuleScript)
local SpeedService     = require(Services:WaitForChild("SpeedService") :: ModuleScript)
local PlotService      = require(Services:WaitForChild("PlotService") :: ModuleScript)
local InventoryService = require(Services:WaitForChild("InventoryService") :: ModuleScript)
local SpawnService     = require(Services:WaitForChild("SpawnService") :: ModuleScript)
local CarryService     = require(Services:WaitForChild("CarryService") :: ModuleScript)
local DisplayService   = require(Services:WaitForChild("DisplayService") :: ModuleScript)
local EconomyService   = require(Services:WaitForChild("EconomyService") :: ModuleScript)
local UnboxService     = require(Services:WaitForChild("UnboxService") :: ModuleScript)
local MonsterService   = require(Services:WaitForChild("MonsterService") :: ModuleScript)

----------------------------------------------------------------------
-- Phase 1: Init (set up internal state, no cross-service calls yet)
----------------------------------------------------------------------
print("[Main] === Initializing Services ===")

DataService.Init()
SpeedService.Init()
PlotService.Init()
InventoryService.Init()
SpawnService.Init()
CarryService.Init()
DisplayService.Init()
EconomyService.Init()
UnboxService.Init()
MonsterService.Init()

----------------------------------------------------------------------
-- Phase 2: Start (connect events, cross-service references OK)
----------------------------------------------------------------------
print("[Main] === Starting Services ===")

DataService.Start()
SpeedService.Start()
PlotService.Start()
InventoryService.Start()
SpawnService.Start()
CarryService.Start()
DisplayService.Start()
EconomyService.Start()
UnboxService.Start()
MonsterService.Start()

----------------------------------------------------------------------
-- Player Lifecycle
----------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	print("[Main] Player joined: " .. player.Name .. " (" .. player.UserId .. ")")
	SpeedService.OnPlayerAdded(player)
	PlotService.OnPlayerAdded(player)
	EconomyService.OnPlayerAdded(player)
	InventoryService.OnPlayerAdded(player)
end

local function onPlayerRemoving(player: Player)
	print("[Main] Player leaving: " .. player.Name)
	CarryService.OnPlayerRemoving(player)
	DisplayService.OnPlayerRemoving(player)
	PlotService.OnPlayerRemoving(player)
	EconomyService.OnPlayerRemoving(player)
	InventoryService.OnPlayerRemoving(player)
	SpeedService.OnPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (e.g. Studio test mode)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

----------------------------------------------------------------------
-- Wire RequestDropBox Remote Event
----------------------------------------------------------------------
local dropBoxEvent = Network.GetEvent(Network.Events.RequestDropBox)
dropBoxEvent.OnServerEvent:Connect(function(player: Player)
	local notify = Network.GetEvent(Network.Events.NotifyFeedback)

	if not CarryService.IsCarrying(player) then
		notify:FireClient(player, "You are not carrying a box!", "Warning")
		return
	end

	local success = CarryService.DropBox(player)
	if success then
		notify:FireClient(player, "📦 You dropped the Mystery Box!", "Warning")
	else
		notify:FireClient(player, "Failed to drop the box!", "Error")
	end
end)

print("[Main] === Steal a Mystery Box! Server Ready ===")
