--!strict
--[[
	BiomesConfig — Biome definitions for Steal a Mystery Box!
	Authority: Single Mystery Box per Biome & WorldMapV1.png.
	Each biome spawns exactly ONE type of Mystery Box (e.g. Urban Mystery Box).
	Loot chances and item rarities are rolled on the Unbox Pad via LootTablesConfig.
]]

export type BiomeConfig = {
	id: string,
	displayName: string,
	worldOrder: number,
	unlockedForMVP: boolean,
	maxActiveBoxes: number,
	spawnPointCount: number,
	respawnCooldownRange: { min: number, max: number },
	boxTypeId: string?,
}

local BiomesConfig: { [string]: BiomeConfig } = {
	Safezone = {
		id = "Safezone",
		displayName = "Safezone",
		worldOrder = 0,
		unlockedForMVP = true,
		maxActiveBoxes = 0, -- No boxes spawn here [LOCKED]
		spawnPointCount = 0,
		respawnCooldownRange = { min = 0, max = 0 },
		boxTypeId = nil,
	},

	Urban = {
		id = "Urban",
		displayName = "Urban",
		worldOrder = 1,
		unlockedForMVP = true,
		maxActiveBoxes = 6,
		spawnPointCount = 12,
		respawnCooldownRange = { min = 25, max = 45 },
		boxTypeId = "Urban_Box",
	},

	Slums = {
		id = "Slums",
		displayName = "Slums",
		worldOrder = 2,
		unlockedForMVP = true,
		maxActiveBoxes = 6,
		spawnPointCount = 12,
		respawnCooldownRange = { min = 25, max = 45 },
		boxTypeId = "Slums_Box",
	},

	Mountain = {
		id = "Mountain",
		displayName = "Mountain",
		worldOrder = 3,
		unlockedForMVP = false, -- [POST-MVP]
		maxActiveBoxes = 6,
		spawnPointCount = 12,
		respawnCooldownRange = { min = 25, max = 45 },
		boxTypeId = "Mountain_Box",
	},

	Ocean = {
		id = "Ocean",
		displayName = "Ocean",
		worldOrder = 4,
		unlockedForMVP = false, -- [POST-MVP]
		maxActiveBoxes = 6,
		spawnPointCount = 12,
		respawnCooldownRange = { min = 25, max = 45 },
		boxTypeId = "Ocean_Box",
	},

	Space = {
		id = "Space",
		displayName = "Space",
		worldOrder = 5,
		unlockedForMVP = false, -- [POST-MVP]
		maxActiveBoxes = 6,
		spawnPointCount = 12,
		respawnCooldownRange = { min = 25, max = 45 },
		boxTypeId = "Space_Box",
	},
}

return BiomesConfig

