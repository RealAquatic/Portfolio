--[[

Module script inside of serverscriptservice -> PlayerInventoryModules folder

]]

local InventoryModule = {}

-- Item slots
InventoryModule.EquippedItems = {
	[1] = "Empty",
	[2] = "Empty",
	[3] = "Empty",
	[4] = "Empty",
	[5] = "Empty"
}

-- Current player inventory
InventoryModule.Inventory = {
	Armor = {
	},
	
	Weapon = {
		"Hammer",
		"Longsword",
		"Hammer",	
	},
	
	Relic = {
	},
	
	Tools = {
		"Torch",
	},
	
	Mount = {
	},
	
	Ally = {
	},
}



-- For every item you make, you also need to give it a category.

InventoryModule.CategoryMapping = {
	["Torch"] = "Tools",
	["Hammer"] = "Weapon",
	["Longsword"] = "Weapon",
}

-- When Creating any new items, make sure to add their data in this format

InventoryModule.ArmorData = {
}
InventoryModule.WeaponData = {
	["Hammer"] = {
		["Rarity"] = "Common",
		["Description"] = "A Great big hammer. Great at dealing large one-hit damage!",
	},
	["Longsword"] = {
		["Rarity"] = "Common",
		["Description"] = "A sharp long sword. Great at swift and decisive blows!",
	}
}

InventoryModule.RelicData = {
}

InventoryModule.ToolsData = {
	["Torch"] = {
		["Rarity"] = "Common",
		["Description"] = "A Common Tool. Lightweight and not very valuable.",
	}
}

InventoryModule.MountData = {
}

InventoryModule.AllyData = {
}

return InventoryModule


