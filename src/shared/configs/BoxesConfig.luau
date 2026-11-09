--!strict
--[[
	BoxesConfig — Box definitions and data contracts.
	Authority: Single Mystery Box per Biome.
	
	Game Design Rule:
	  Each biome has exactly ONE Mystery Box.
	  When opened at the unbox pad, that box rolls for different item rarities
	  (Common, Uncommon, Rare, Epic, Legendary, Secret) based on the biome's loot chances.
]]

export type BoxDefinition = {
	boxTypeId: string,
	name: string,
	biomeId: string,
	displayName: string,
	themeColor: Color3,
	modelKey: string,
	iconKey: string,
	lootTableKey: string,
}

local BoxesConfig = {}

-- Carry settings
BoxesConfig.Carry = {
	maxBoxesPerPlayer = 1,
	pickupRange = 8, -- studs, server-validated
	pickupHoldTime = 0.4, -- seconds
	carrySpeedMultiplier = 0.80, -- 80% of normal walk speed
}

local definitions: { [string]: BoxDefinition } = {
	Urban_Box = {
		boxTypeId = "Urban_Box",
		name = "Urban Mystery Box",
		biomeId = "Urban",
		displayName = "Urban Mystery Box",
		themeColor = Color3.fromRGB(0, 190, 255),
		modelKey = "Box_Urban",
		iconKey = "Icon_Box_Urban",
		lootTableKey = "Urban",
	},

	Slums_Box = {
		boxTypeId = "Slums_Box",
		name = "Slums Mystery Box",
		biomeId = "Slums",
		displayName = "Slums Mystery Box",
		themeColor = Color3.fromRGB(230, 115, 45),
		modelKey = "Box_Slums",
		iconKey = "Icon_Box_Slums",
		lootTableKey = "Slums",
	},

	Mountain_Box = {
		boxTypeId = "Mountain_Box",
		name = "Mountain Mystery Box",
		biomeId = "Mountain",
		displayName = "Mountain Mystery Box",
		themeColor = Color3.fromRGB(46, 175, 80),
		modelKey = "Box_Mountain",
		iconKey = "Icon_Box_Mountain",
		lootTableKey = "Mountain",
	},

	Space_Box = {
		boxTypeId = "Space_Box",
		name = "Space Mystery Box",
		biomeId = "Space",
		displayName = "Space Mystery Box",
		themeColor = Color3.fromRGB(170, 80, 255),
		modelKey = "Box_Space",
		iconKey = "Icon_Box_Space",
		lootTableKey = "Space",
	},

	Ocean_Box = {
		boxTypeId = "Ocean_Box",
		name = "Ocean Mystery Box",
		biomeId = "Ocean",
		displayName = "Ocean Mystery Box",
		themeColor = Color3.fromRGB(0, 210, 230),
		modelKey = "Box_Ocean",
		iconKey = "Icon_Box_Ocean",
		lootTableKey = "Ocean",
	},
}

BoxesConfig.Definitions = definitions

function BoxesConfig.GetBox(boxTypeId: string): BoxDefinition?
	return BoxesConfig.Definitions[boxTypeId]
end

return BoxesConfig
