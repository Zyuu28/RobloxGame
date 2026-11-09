--!strict
--[[
	DataService — Manages player data persistence via DataStoreService.
	Authority: GDD §12.3, §12.4.
	Status: STUB (Phase 0). Logic deferred to Phase 4.
	
	Responsibilities (P4):
	  - Load player profile on join (with pcall + retry)
	  - Save player profile on leave and periodic auto-save
	  - Schema versioning and migration
	  - Session locking via UpdateAsync with session GUID (see DECISION_LOG.md #D-OQ6)
	  - On failed load: block mutations, show retry/leave message
	  - Never overwrite good data after a failed load
	  - BindToClose for graceful shutdown saves
	
	Data schema follows GDD §12.3 PlayerProfile structure.
]]

local DataService = {}

function DataService.Init()
	print("[DataService] Initialized (stub).")
end

function DataService.Start()
	print("[DataService] Started (stub).")
end

return DataService

