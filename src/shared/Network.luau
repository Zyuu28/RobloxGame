--!strict
--[[
	Network — Central RemoteEvent and RemoteFunction registry for Steal a Mystery Box!
	Authority: GDD §12.1.
	
	Ensures all Remotes exist in ReplicatedStorage.Shared.Remotes.
	Provides safe server and client accessors to avoid race conditions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = {}

-- Remote Names
Network.Events = {
	StateUpdate = "StateUpdate",           -- Server -> Client: Replicates player state (bucks, inventory, plot, etc.)
	NotifyFeedback = "NotifyFeedback",     -- Server -> Client: Feedback toasts (error, success, warnings)
	UnboxReveal = "UnboxReveal",           -- Server -> Client: Trigger unbox reveal sequence with item data
	RequestPickup = "RequestPickup",       -- Client -> Server: Request to pick up a world mystery box
	RequestUnbox = "RequestUnbox",         -- Client -> Server: Request to unbox held box at plot
	RequestDisplay = "RequestDisplay",     -- Client -> Server: Request to place an item on a display stand
	RequestUndisplay = "RequestUndisplay", -- Client -> Server: Request to remove an item from a display stand
	RequestEquip = "RequestEquip",         -- Client -> Server: Request to equip a wearable accessory
	RequestUnequip = "RequestUnequip",     -- Client -> Server: Request to unequip a wearable accessory
	RequestClaim = "RequestClaim",         -- Client -> Server: Request to collect pending display earnings
	RequestUpgrade = "RequestUpgrade",     -- Client -> Server: Request to purchase a capacity upgrade
	RequestDropBox = "RequestDropBox",     -- Client -> Server: Request to drop the carried mystery box
}

local remotesFolder: Folder

local function getRemotesFolder(): Folder
	if remotesFolder then
		return remotesFolder
	end

	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	if not shared then
		shared = Instance.new("Folder")
		shared.Name = "Shared"
		shared.Parent = ReplicatedStorage
	end

	local folder = shared:FindFirstChild("Remotes")
	if not folder then
		if RunService:IsServer() then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = shared
		else
			folder = shared:WaitForChild("Remotes", 10) :: Folder
		end
	end

	remotesFolder = folder :: Folder
	return remotesFolder
end

-- Server initialization: ensures all RemoteEvents exist
function Network.InitServer()
	assert(RunService:IsServer(), "[Network] InitServer can only be called on the Server!")
	local folder = getRemotesFolder()

	for _, remoteName in pairs(Network.Events) do
		local existing = folder:FindFirstChild(remoteName)
		if not existing then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = folder
		end
	end
	print("[Network] Server Remotes initialized in ReplicatedStorage.Shared.Remotes")
end

-- Get a RemoteEvent safely on Server or Client
function Network.GetEvent(name: string): RemoteEvent
	local folder = getRemotesFolder()
	local remote = folder:FindFirstChild(name)
	if not remote then
		if RunService:IsServer() then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		else
			remote = folder:WaitForChild(name, 10) :: RemoteEvent
		end
	end
	assert(remote and remote:IsA("RemoteEvent"), "[Network] RemoteEvent '" .. name .. "' not found!")
	return remote :: RemoteEvent
end

return Network
