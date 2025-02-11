--[[

Will not work without an instancer made by @Enxquity.
Inside of ServerScriptService -> Initilise.

]]

local InventoryCommands = {
	Services = {
		PlayerInventoryEvent = game:GetService("ReplicatedStorage").Events.PlayerInventory,
		Players = game:GetService("Players"),
		PlayerInventoryFolder = game:GetService("ServerScriptService").PlayerInventoryModules,
		InventoryTemplate = game:GetService("ServerScriptService").PlayerInventoryModules.InventoryTemplate
	}
}

-- Add some warnings and anti error thingies


function InventoryCommands:AddItem(Inventory, Category, Item)
	table.insert(Inventory.Inventory[Category], Item)
end


function InventoryCommands:RemoveItem(Inventory, Category, Item)
	for i, v in pairs(Inventory.Inventory) do
		if v == Item then
			table.remove(Inventory.Inventory[Category], i) 
			break
		end
	end
end


function InventoryCommands:GetAmountOf(Inventory, Category, Item)
	
	local Amount = 0
	for i, v in pairs(Inventory.Inventory[Category]) do
		if v == Item then
			Amount += 1 
		end
	end
	
	return Amount
	
end

function InventoryCommands:GetData(Inventory, Category)
	return Inventory[Category .. "Data"]
end

function InventoryCommands:Load(Modules)
	local self: typeof(InventoryCommands) = self
	self.Modules = Modules	

	self.Services.Players.PlayerAdded:Connect(function(player)
		
		local PlayerInventoryModule = self.Services.InventoryTemplate:Clone()
		PlayerInventoryModule.Name = player.UserId
		PlayerInventoryModule.Parent = self.Services.PlayerInventoryFolder
		PlayerInventoryModule = require(PlayerInventoryModule)
		
	end)
	
	self.Services.PlayerInventoryEvent.OnServerInvoke = function(player, CategoryType, CommandType)
		local PlayerInventory = require(self.Services.PlayerInventoryFolder[player.UserId])
		
		if CommandType == "ReturnInventory" then
			if PlayerInventory.Inventory and PlayerInventory.Inventory[CategoryType] then
				return(PlayerInventory.Inventory[CategoryType])
			else
				warn("Invalid category or inventory not found for player:", player.UserId, "Category:", CategoryType)
			end			
		elseif CommandType == "GetData" then
			return self:GetData(PlayerInventory, CategoryType)
		end

	end
	

end

return InventoryCommands
