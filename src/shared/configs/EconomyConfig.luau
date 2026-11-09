--!strict
--[[
	EconomyConfig — Economy parameters for Steal a Mystery Box!
	Authority: GDD §8, §8.1.
	All values are [PROPOSED] placeholders for balance tuning.
]]

local EconomyConfig = {
	-- Starting currency
	baseBucks = 0, -- [PROPOSED] First collectible is free to obtain

	-- Display stands
	freeDisplayStands = 3, -- [PROPOSED] Per plot at start

	-- Inventory
	baseInventoryCapacity = 20, -- [PROPOSED] Level 0

	-- Open Question #1 resolution: does a displayed item count toward inventory?
	-- false = displayed items do NOT reduce available inventory slots
	-- true  = displayed items DO count against capacity
	displayedCountsAsInventory = false, -- [PROPOSED] see DECISION_LOG.md #D-OQ1

	-- Income system
	economyTickInterval = 1, -- seconds between server-side income calculations
	offlineIncome = false,   -- [LOCKED OFF] for MVP (GDD §8)

	-- Money Collector
	pendingBucksCap = nil, -- uncapped [PROPOSED] see DECISION_LOG.md #D-OQ7
	-- Set to a number (e.g. 10000) to cap pending earnings

	-- Sell / discard
	sellEnabled = false, -- [LOCKED OFF] for MVP (GDD §8)

	-- Income per rarity [PROPOSED] — used as fallback if a collectible has no explicit value
	-- Primary source of truth is CollectiblesConfig per-item incomePerSecond
	defaultIncomeByRarity = {
		Common    = 2,
		Uncommon  = 5,
		Rare      = 15,
		Epic      = 40,
		Legendary = 100,
		Secret    = 250,
	},
}

return EconomyConfig

