--[[

Module script inside of serverscriptservice -> PlayerInventoryModules folder

]]

local InventoryModule = {}

InventoryModule.Inventory = {
	Armor = {
		"Armor1",
		"Armor2"
	},
	Weapon = {
		"Weapon1"
	},
	Relic = {
		"Relic1"
	},
	Tools = {
		"Tools1"
	},
	Mount = {
		"Mount1"
	},
	Ally = {
		"Ally1"
	},
}
-- When Creating any new items, make sure to add their data in this format
InventoryModule.ArmorData = {
	["Armor1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Armour piece. Lightweight and not very valuable.",
	},
	["Armor2"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Armour piece. Lightweight and not very valuable.",
	}
}
InventoryModule.WeaponData = {
	["Weapon1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Weapon. Lightweight and not very valuable.",
	}
}

InventoryModule.RelicData = {
	["Relic1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Relic. Lightweight and not very valuable.",
	}
}

InventoryModule.ToolsData = {
	["Tools1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Tool. Lightweight and not very valuable.",
	}
}

InventoryModule.MountData = {
	["Mount1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Mount.",
	}
}

InventoryModule.AllyData = {
	["Ally1"] = {
		["Icon"] = 76969385570133,
		["Rarity"] = "Common",
		["Description"] = "A Common Ally.",
	}
}

return InventoryModule


