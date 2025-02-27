--[[

Will not work without an instancer made by @Enxquity.
Inside of ServerScriptService -> Initilise.

]]

local InventoryCommands = {
	Services = {
		ManageItemEvent = game:GetService("ReplicatedStorage").Events.ManageItem,
		PlayerInventoryEvent = game:GetService("ReplicatedStorage").Events.PlayerInventory,
		Players = game:GetService("Players"),
		PlayerInventoryFolder = game:GetService("ServerScriptService").PlayerInventoryModules,
		InventoryTemplate = game:GetService("ServerScriptService").PlayerInventoryModules.InventoryTemplate,
		ServerStorage = game:GetService("ServerStorage")
	}
}

--[[

Inventory Management

]]

function InventoryCommands:AddItem(Inventory, Category, Item)
	table.insert(Inventory.Inventory[Category], Item)
end

function InventoryCommands:RemoveItem(Inventory, Category, Item)
	for i, v in ipairs(Inventory.Inventory[Category]) do
		if v == Item then
			table.remove(Inventory.Inventory[Category], i) 
			break
		end
	end
end

function InventoryCommands:GetAmountOf(Inventory, Category, Item)
	local Amount = 0
	for i, v in ipairs(Inventory.Inventory[Category]) do
		if v == Item then
			Amount += 1 
		end
	end

	return Amount
end

--[[

Util Functions

]]

--GetEquipped: returns the currently equipped items of an inventory
	--@Inventory: Which inventory it is getting the equipped items from
function InventoryCommands:GetEquipped(Inventory: string)
	return Inventory.EquippedItems
end

--EquipItem: Will equip the item in the slot given, returns nil if it fails
	--@Inventory: Which inventory it is going into
	--@Item: What item you want to equip
	--@Slot: Which slot it will go into
function InventoryCommands:EquipItem(Inventory: string, Item: string, Slot: NumberValue)
	Inventory.EquippedItems[Slot] = Item
end


--UnequipItem: Will unequip the item with the given slot.
	--@Inventory: Which inventory it is going into
	--@Slot: Which slot it will remove from
function InventoryCommands:UnequipItem(Inventory: string, Slot: string)
	Inventory.EquippedItems[Slot] = "Empty"
end

-- MapRawData: Will take an item and convert it to its corresponding category.
	--@Inventory: The inventory. Needed.
	--@Item: The item that gets mapped to the category for the inventory
function InventoryCommands:MapRawData(Inventory: string, Item: string)
	if not Inventory.CategoryMapping[Item] then
		warn("Item does not have a category assigned in mapping! Will not work!")
		return nil
	else
		return Inventory.CategoryMapping[Item]
	end
end

function InventoryCommands:GetData(Inventory, Category)
	return Inventory[Category .. "Data"]
end

--[[

Manage Item Event Functions

]]

function InventoryCommands:GiveItem(Player, Item)
	local Backpack = Player:FindFirstChild("Backpack")
	local ItemToGive = InventoryCommands.Services.ServerStorage.Items[Item]:Clone()
	ItemToGive.Parent = Backpack
end

function InventoryCommands:DestroyItem(Player, Item)
	local Backpack = Player:FindFirstChild("Backpack")
	Backpack[Item]:Destroy()
end

function InventoryCommands:CloneItem(Player, Item)
	local ClonedItem = InventoryCommands.Services.ServerStorage.Items[Item]:Clone()
	ClonedItem.PrimaryPart = ClonedItem:WaitForChild("Handle")
	ClonedItem.PrimaryPart.Anchored = true
	ClonedItem.Parent = workspace:WaitForChild("WeaponsCloned")
end

--[[

Loader

]]
function InventoryCommands:Load(Modules)
	local self: typeof(InventoryCommands) = self
	self.Modules = Modules	

	-- Once datastore system made, move this to there so you can save the inventory as a list 

	self.Services.Players.PlayerAdded:Connect(function(player)
		
		local PlayerInventoryModule = self.Services.InventoryTemplate:Clone()
		PlayerInventoryModule.Name = player.UserId
		PlayerInventoryModule.Parent = self.Services.PlayerInventoryFolder
		PlayerInventoryModule = require(PlayerInventoryModule)
		
		
	end)
	
	self.Services.PlayerInventoryEvent.OnServerInvoke = function(player, Slot: NumberValue?, ItemOrCategory: string?, CommandType: string)
		local PlayerInventory = require(self.Services.PlayerInventoryFolder[player.UserId])
		
		if CommandType == "ReturnInventory" then
			if ItemOrCategory == nil then
				return(PlayerInventory.Inventory)
			end
			if PlayerInventory.Inventory and PlayerInventory.Inventory[ItemOrCategory] then
				return(PlayerInventory.Inventory[ItemOrCategory])
			else
				warn("Invalid category or inventory not found for player:", player.UserId, "Category:", ItemOrCategory)
			end			
		elseif CommandType == "GetData" then
			return self:GetData(PlayerInventory, ItemOrCategory)
		elseif CommandType == "MapRawData" then
			return self:MapRawData(PlayerInventory, ItemOrCategory)
		elseif CommandType == "GetEquipped" then
			return self:GetEquipped(PlayerInventory)
		elseif CommandType == "EquipItem" then
			self:EquipItem(PlayerInventory, ItemOrCategory, Slot)
		elseif CommandType == "UnequipItem" then
			self:UnequipItem(PlayerInventory, Slot)
		else
			warn("Invalid Command!")
		end
	end
	
	self.Services.ManageItemEvent.OnServerInvoke = function(player, Item: string, CommandType: string)
		if CommandType == "GiveItem" then
			self:GiveItem(player, Item)
		elseif CommandType == "DestroyItem" then
			self:DestroyItem(player, Item)
		elseif CommandType == "CloneItem" then
			self:CloneItem(player, Item)	
		else
			warn("Invalid Command!")
		end
	end
	
end

return InventoryCommands
