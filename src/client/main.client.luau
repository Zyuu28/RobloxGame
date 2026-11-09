--!strict
--[[
	Main Client Bootstrap — Steal a Mystery Box!
	
	Initializes all client controllers in order,
	then starts them for event connections.
	
	Uses WaitForChild to prevent race conditions during replication.
]]

local StarterPlayerScripts = script.Parent
local Controllers = StarterPlayerScripts:WaitForChild("Controllers", 10)
assert(Controllers, "[ClientMain] Controllers folder not found in PlayerScripts!")

local UIManager             = require(Controllers:WaitForChild("UIManager") :: ModuleScript)
local HUDController         = require(Controllers:WaitForChild("HUDController") :: ModuleScript)
local InventoryController   = require(Controllers:WaitForChild("InventoryController") :: ModuleScript)
local UnboxController       = require(Controllers:WaitForChild("UnboxController") :: ModuleScript)
local InteractionController = require(Controllers:WaitForChild("InteractionController") :: ModuleScript)

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
print("[ClientMain] === Initializing Controllers ===")

UIManager.Init()
HUDController.Init()
InventoryController.Init()
UnboxController.Init()
InteractionController.Init()

----------------------------------------------------------------------
-- Start
----------------------------------------------------------------------
print("[ClientMain] === Starting Controllers ===")

HUDController.Start()
InventoryController.Start()
UnboxController.Start()
InteractionController.Start()

print("[ClientMain] === Client Ready ===")
