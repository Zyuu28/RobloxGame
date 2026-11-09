--!strict
--[[
	UpgradesConfig — Upgrade path definitions.
	Authority: GDD §8.1.
	All costs are [PROPOSED] placeholders for balance tuning.
]]

export type UpgradeLevel = {
	level: number,
	costBucks: number,  -- 0 = free / starting tier
	newCapacity: number,
}

export type UpgradeDefinition = {
	upgradeId: string,
	displayName: string,
	description: string,
	maxLevel: number,
	levels: { UpgradeLevel },
}

local UpgradesConfig: { [string]: UpgradeDefinition } = {
	InventoryCapacity = {
		upgradeId = "InventoryCapacity",
		displayName = "Inventory Capacity",
		description = "Increase the number of collectibles you can hold.",
		maxLevel = 3,
		levels = {
			{ level = 0, costBucks = 0,    newCapacity = 20 },
			{ level = 1, costBucks = 150,  newCapacity = 30 },
			{ level = 2, costBucks = 500,  newCapacity = 45 },
			{ level = 3, costBucks = 1500, newCapacity = 65 },
		},
	},

	DisplayStandCapacity = {
		upgradeId = "DisplayStandCapacity",
		displayName = "Display Stand Capacity",
		description = "Increase the number of display stands on your plot.",
		maxLevel = 3,
		levels = {
			{ level = 0, costBucks = 0,    newCapacity = 3 },
			{ level = 1, costBucks = 250,  newCapacity = 4 },
			{ level = 2, costBucks = 850,  newCapacity = 5 },
			{ level = 3, costBucks = 2500, newCapacity = 6 },
		},
	},

	WalkSpeed = {
		upgradeId = "WalkSpeed",
		displayName = "Walk Speed",
		description = "Increase your avatar sprint and movement speed across the world.",
		maxLevel = 3,
		levels = {
			{ level = 0, costBucks = 0,    newCapacity = 16 }, -- Roblox Default base speed
			{ level = 1, costBucks = 200,  newCapacity = 24 }, -- Level 1 sprint
			{ level = 2, costBucks = 750,  newCapacity = 35 }, -- Level 2 turbo
			{ level = 3, costBucks = 2000, newCapacity = 50 }, -- Level 3 sonic max
		},
	},
}

return UpgradesConfig

