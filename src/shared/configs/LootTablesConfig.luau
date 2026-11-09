--!strict
--[[
	LootTablesConfig — Reward loot tables per Biome.
	Authority: Single Mystery Box per Biome.
	
	Game Design Rule:
	  Each biome has ONE Mystery Box. Opening it rolls from the biome's loot table,
	  which contains chances to obtain collectibles ranging from Common to Secret.
]]

export type LootEntry = {
	itemId: string,
	weight: number,
	rarity: string,
}

export type LootTable = {
	biomeId: string,
	entries: { LootEntry },
	totalWeight: number,
}

local LootTablesConfig: { [string]: LootTable } = {}

local function createTable(biomeId: string, rawEntries: { { string | number } }): LootTable
	local entries: { LootEntry } = {}
	local totalWeight = 0
	for _, item in rawEntries do
		local itemId = item[1] :: string
		local weight = item[2] :: number
		local rarity = item[3] :: string
		table.insert(entries, {
			itemId = itemId,
			weight = weight,
			rarity = rarity,
		})
		totalWeight += weight
	end
	return {
		biomeId = biomeId,
		entries = entries,
		totalWeight = totalWeight,
	}
end

----------------------------------------------------------------------
-- 1. URBAN BIOME LOOT TABLE (Total Weight: 1000)
-- Common (50%), Uncommon (25%), Rare (14%), Epic (7.5%), Legendary (3%), Secret (0.5%)
----------------------------------------------------------------------
LootTablesConfig["Urban"] = createTable("Urban", {
	{ "Urban_TrafficBuddy",     260, "Common" },    -- 26%
	{ "Urban_SodaCan",          240, "Common" },    -- 24%
	{ "Urban_MiniSkyscraper",   250, "Uncommon" },  -- 25%
	{ "Urban_StreetBot",        140, "Rare" },      -- 14%
	{ "Urban_GoldenTaxi",        75, "Epic" },      -- 7.5%
	{ "Urban_CyberpunkDJ",       30, "Legendary" }, -- 3.0%
	{ "Urban_CityGuardian",       5, "Secret" },    -- 0.5%
})

----------------------------------------------------------------------
-- 2. SLUMS BIOME LOOT TABLE (Total Weight: 1000)
-- Common (50%), Uncommon (25%), Rare (14%), Epic (7.5%), Legendary (3%), Secret (0.5%)
----------------------------------------------------------------------
LootTablesConfig["Slums"] = createTable("Slums", {
	{ "Slums_CardboardBuddy",   260, "Common" },    -- 26%
	{ "Slums_RustyCan",         240, "Common" },    -- 24%
	{ "Slums_TireMonster",      250, "Uncommon" },  -- 25%
	{ "Slums_ScrapRobot",       140, "Rare" },      -- 14%
	{ "Slums_JunkyardKing",      75, "Epic" },      -- 7.5%
	{ "Slums_StreetPhantom",     30, "Legendary" }, -- 3.0%
	{ "Slums_ScrapTitan",         5, "Secret" },    -- 0.5%
})

--[[
	Roll a random item from a given Biome (e.g. "Urban" or "Slums").
	Server-authoritative weighted random roll.
]]
function LootTablesConfig.RollItem(biomeId: string): string
	local tableDef = LootTablesConfig[biomeId]
	if not tableDef or #tableDef.entries == 0 then
		-- Fallback to Urban
		tableDef = LootTablesConfig["Urban"]
	end

	local roll = math.random(1, tableDef.totalWeight)
	local current = 0
	for _, entry in tableDef.entries do
		current += entry.weight
		if roll <= current then
			return entry.itemId
		end
	end

	return tableDef.entries[1].itemId
end

function LootTablesConfig.GetTable(biomeId: string): LootTable?
	return LootTablesConfig[biomeId]
end

return LootTablesConfig
