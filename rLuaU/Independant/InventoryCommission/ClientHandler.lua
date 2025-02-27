local Global = require(script.Modules.Global)

local MainUI = Global.PlayerGui:WaitForChild("MainUI")

for _, UI in MainUI.Open:GetChildren() do
	UI.Visible = false
end

-- Needed

local ToolBarFrame =  MainUI.Toolbar

-- LeftButtons

for Name, Info in Global.Info:Get("LeftButtons") do
	local ButtonTemplate = MainUI.Left.ButtonTemplate:Clone()
	ButtonTemplate.Visible = true
	ButtonTemplate.Parent = MainUI.Left
	ButtonTemplate.Name = Name
	ButtonTemplate.Background.Icon.Image = "rbxassetid://".. Info.IconID
	ButtonTemplate.Sideway.TextLayout.Text = Info.LayoutName
	ButtonTemplate.LayoutOrder = Info.LayoutOrder
	
	local SlideButton = Global.UIController.new(Global, "Slide", ButtonTemplate, {
		MouseEnter = function()
			local Sound = script.InterfaceSounds.Enter:Clone()
			Sound.Parent = Global.PlayerGui
			Sound:Play()
			
			Global("Debris", Sound.TimeLength, Sound)
		end,
		MouseLeave = function()
			local Sound = script.InterfaceSounds.Leave:Clone()
			Sound.Parent = Global.PlayerGui
			Sound:Play()
			
			Global("Debris", Sound.TimeLength, Sound)
		end,
		MouseClick = function()
			local Sound = script.InterfaceSounds.Enter:Clone()
			Sound.Parent = Global.PlayerGui
			Sound:Play()

			Global("Debris", Sound.TimeLength, Sound)
		end,
	}, ButtonTemplate.Background.Position, UDim2.new(.8,0,0,0), .3)
end

-- Inventory

local LastTab

function UpdateDisplay(SelectedItem, PlayerInventoryEvent)
	local ItemInfoFrame = MainUI.Open.Inventory.ItemInfo
	local ItemName = ItemInfoFrame.ItemName
	local ItemRarity = ItemInfoFrame.ItemRarity
	local ItemText = ItemInfoFrame.InfoText
	local ItemViewPort = MainUI.Open.Inventory.ItemViewPort
	
	local EquippedItems = PlayerInventoryEvent:InvokeServer(nil, nil, "GetEquipped")
	
	local ItemToSend = PlayerInventoryEvent:InvokeServer(nil, tostring(SelectedItem[1]), "MapRawData")

	if ItemToSend == nil then
		warn("UpdateDisplay will not continue! Returning.")
		return
	end

	local Info = PlayerInventoryEvent:InvokeServer(nil, ItemToSend, "GetData")	

	for _,v in pairs(EquippedItems) do
		if tostring(v) == tostring(SelectedItem[1]) then
			MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(112, 11, 13)
			MainUI.Open.Inventory.Equip.Equip.Text = "Unequip"
			break
		else
			MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(37,112,14)
			MainUI.Open.Inventory.Equip.Equip.Text = "Equip"
		end 
	end

	MainUI.Open.Inventory.Equip.Visible = true

	ItemName.Text = tostring(SelectedItem[1])
	ItemText.Text = Info[tostring(SelectedItem[1])]["Description"]

	local Rarity = Info[tostring(SelectedItem[1])]["Rarity"]

	if Rarity == "Common" then
		ItemRarity.Text = "Common"
		ItemRarity.TextColor3 = Color3.fromRGB(94, 255, 7)
	elseif Rarity == "Rare" then
		ItemRarity.Text = "Rare"
		ItemRarity.TextColor3 = Color3.fromRGB(14, 151, 255)
	elseif Rarity == "Unique" then
		ItemRarity.Text = "Unique"
		ItemRarity.TextColor3 = Color3.fromRGB(255, 0, 0)
	elseif Rarity == "Legendary" then
		ItemRarity.Text = "Legendary"
		ItemRarity.TextColor3 = Color3.fromRGB(255, 179, 0)
	end
	
	local CloneViewport = ItemViewPort.ImageLabel.ViewportFrame:Clone()
	ItemViewPort.ImageLabel.ViewportFrame:Destroy()
	CloneViewport.Parent = ItemViewPort.ImageLabel
	
	local camera = Instance.new("Camera")
	camera.Parent = ItemViewPort.ImageLabel.ViewportFrame
	ItemViewPort.ImageLabel.ViewportFrame.CurrentCamera = camera

	local ClonedItem = game:GetService("ReplicatedStorage").Items:WaitForChild(tostring(SelectedItem[1])):Clone()
	ClonedItem.Parent = ItemViewPort.ImageLabel.ViewportFrame
	local Pos = ClonedItem.PrimaryPart.Position

	local cameraPosition = Pos + Vector3.new(0, 3, 0)
	camera.CFrame = CFrame.new(cameraPosition) * CFrame.Angles(0, math.rad(45), 0) * CFrame.new(0, 0, (cameraPosition - Pos).Magnitude)
	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, Pos)
end

--// Equipping the item \\--

local LastActivatedMapping = {
	["One"] = 1,
	["Two"] = 2,
	["Three"] = 3,
	["Four"] = 4,
	["Five"] = 5,
}


MainUI.Open.Inventory.Equip.MouseButton1Click:Connect(function()
	
	local PlayerInventoryEvent = game.ReplicatedStorage.Events.PlayerInventory
	local EquippedItems = PlayerInventoryEvent:InvokeServer(nil, nil, "GetEquipped")
	
	local ItemToEquip = MainUI.Open.Inventory.ItemInfo.ItemName.Text
	local Category = PlayerInventoryEvent:InvokeServer(nil, ItemToEquip, "MapRawData")
	local PlayerInventory = PlayerInventoryEvent:InvokeServer(nil, Category, "ReturnInventory")
	
	if LastActivated == nil then
		for index, item in pairs(EquippedItems) do
			if item == ItemToEquip then
				PlayerInventoryEvent:InvokeServer(index, nil, "UnequipItem")
				MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(37,112,14)
				MainUI.Open.Inventory.Equip.Equip.Text = "Equip"
				UpdateToolBar(ToolBarFrame)
				
				local ManageItemEvent = game.ReplicatedStorage.Events.ManageItem
				ManageItemEvent:InvokeServer(ItemToEquip, "DestroyItem")
				
				return
			end
		end

		for index, item in pairs(EquippedItems) do
			if item == "Empty" then
				PlayerInventoryEvent:InvokeServer(index, ItemToEquip, "EquipItem")
				MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(112, 11, 13)
				MainUI.Open.Inventory.Equip.Equip.Text = "Unequip"
				UpdateToolBar(ToolBarFrame)
				
				local ManageItemEvent = game.ReplicatedStorage.Events.ManageItem
				ManageItemEvent:InvokeServer(ItemToEquip, "GiveItem")
				
				return
			end
		end
	else
		local Slot = LastActivatedMapping[tostring(LastActivated)]
		if MainUI.Open.Inventory.Equip.Equip.Text == "Unequip" then
			
			for i,v in pairs(EquippedItems) do
				if v == ItemToEquip then
					PlayerInventoryEvent:InvokeServer(i, nil, "UnequipItem")
					MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(37,112,14)
					MainUI.Open.Inventory.Equip.Equip.Text = "Equip"
					UpdateToolBar(ToolBarFrame)
					
					local ManageItemEvent = game.ReplicatedStorage.Events.ManageItem
					ManageItemEvent:InvokeServer(ItemToEquip, "DestroyItem")
					
					return
				end
			end
			
		elseif MainUI.Open.Inventory.Equip.Equip.Text == "Equip" then
			PlayerInventoryEvent:InvokeServer(Slot, ItemToEquip, "EquipItem")
			MainUI.Open.Inventory.Equip.Equip.TextColor3 = Color3.fromRGB(112, 11, 13)
			MainUI.Open.Inventory.Equip.Equip.Text = "Unequip"
			UpdateToolBar(ToolBarFrame)
			
			local ManageItemEvent = game.ReplicatedStorage.Events.ManageItem
			ManageItemEvent:InvokeServer(ItemToEquip, "GiveItem")
			
			return	
		end
	end

	warn("No empty slots available.")
end)

function CleanInventory(Name, PlayerInventory)
	for _, v in MainUI.Open.Inventory.ScrollingTabs[Name].ScrollingFrame:GetChildren() do
		if v:IsA("Frame") then 
			v:Destroy()
		end
	end
end

function UpdateInventory(Name, PlayerInventory, ItemData)

	CleanInventory(Name, PlayerInventory)

	local Slots = 18
	
	for i, v in ipairs(PlayerInventory) do
		
		
		local ItemTemplate = MainUI.Open.Inventory.ScrollingTabs.Template.ScrollingFrame.Template:Clone()
		ItemTemplate.Visible = true
		ItemTemplate.Parent = MainUI.Open.Inventory.ScrollingTabs[Name].ScrollingFrame
		ItemTemplate.Name = v

		if ItemData[v] then
			ItemTemplate.ImageLabel.ImageColor3 = Color3.fromRGB(130,130,130)
			
			local camera = Instance.new("Camera")
			camera.Parent = ItemTemplate.ImageLabel.ViewportFrame
			ItemTemplate.ImageLabel.ViewportFrame.CurrentCamera = camera
		
			local ClonedItem = game:GetService("ReplicatedStorage").Items:WaitForChild(v):Clone()
			ClonedItem.Parent = ItemTemplate.ImageLabel.ViewportFrame
			local Pos = ClonedItem.PrimaryPart.Position

			local cameraPosition = Pos + Vector3.new(0, 3, 0)
			camera.CFrame = CFrame.new(cameraPosition) * CFrame.Angles(0, math.rad(45), 0) * CFrame.new(0, 0, (cameraPosition - Pos).Magnitude)
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, Pos)

			ItemTemplate.ImageLabel.ImageLabel.ImageTransparency = 0
		else
			warn("Item not found in ItemData:", v)
		end
		Slots -=1

	end

	if Slots >= 1 then
		for i=1, Slots do
			local ItemTemplate = MainUI.Open.Inventory.ScrollingTabs.Template.ScrollingFrame.Frame:Clone()
			ItemTemplate.Visible = true
			ItemTemplate.Parent = MainUI.Open.Inventory.ScrollingTabs[Name].ScrollingFrame
			ItemTemplate.Name = "Empty"
			ItemTemplate.ImageLabel.ImageColor3 = Color3.fromRGB(130,130,130)
		end
	end

end

for Name, Info in Global.Info:Get("InventoryTabs") do

	local ButtonTemplate = MainUI.Open.Inventory.Tabs.Template:Clone()
	ButtonTemplate.Visible = true
	ButtonTemplate.Parent = MainUI.Open.Inventory.Tabs
	ButtonTemplate.Name = Name
	ButtonTemplate.Icon.Image = "rbxassetid://".. Info.IconID
	ButtonTemplate.LayoutOrder = Info.LayoutOrder

	local ScrollTemplate = MainUI.Open.Inventory.ScrollingTabs.Template:Clone()
	ScrollTemplate.Visible = false
	ScrollTemplate.Parent = MainUI.Open.Inventory.ScrollingTabs
	ScrollTemplate.Name = Name

	ButtonTemplate.Button.MouseButton1Click:Connect(function()
		for _, Buttons in MainUI.Open.Inventory.Tabs:GetChildren() do
			if not Buttons:IsA("Frame") then continue end
			Global("Tween", Buttons.Icon, TweenInfo.new(.5), {ImageColor3 = Color3.fromRGB(130,130,130)})
		end

		Global("Tween", ButtonTemplate.Icon, TweenInfo.new(.5), {ImageColor3 = Color3.fromRGB(255,255,255)})

		if LastTab then LastTab.Visible = false end

		local ButtonTab = MainUI.Open.Inventory.ScrollingTabs[Name]



		local PlayerInventoryEvent = game.ReplicatedStorage.Events.PlayerInventory
		local PlayerInventory = PlayerInventoryEvent:InvokeServer(nil, Name, "ReturnInventory")
		local ItemData = PlayerInventoryEvent:InvokeServer(nil, Name, "GetData")		

		UpdateInventory(Name, PlayerInventory, ItemData)

		local SelectedItem = {}

		for _, frame in MainUI.Open.Inventory.ScrollingTabs:GetChildren() do
			if frame:IsA("Frame") and frame.Name ~= "Template" then
				for _, item in frame.ScrollingFrame:GetChildren() do
					if item:IsA("Frame") and item.Name ~= "Frame" and item.Name ~= "Template" and item.Name ~= "Empty" then
						item.Button.MouseButton1Click:Connect(function()

							if SelectedItem[1] then
								SelectedItem[1].ImageLabel.ImageColor3 = Color3.new(130/255, 130/255 , 130/255)
								table.clear(SelectedItem)
							end

							table.insert(SelectedItem, item)


							item.ImageLabel.ImageColor3 = Color3.new(1, 1, 1)

							UpdateDisplay(SelectedItem, PlayerInventoryEvent)

						end)
					end
				end
			end
		end


		ButtonTab.Visible = true

		LastTab = ButtonTab
	end)
end


-- ToolBar

local Keys = {
	"One",
	"Two",
	"Three",
	"Four",
	"Five",
	--"Six",
	--"Seven",
	--"Eight",
	--"Nine",
	--"Zero"
}

LastActivated = nil

function CleanToolBar(Frame)
	for _, Frame2 in Frame:GetChildren() do
		if Frame2.Name ~= "ItemTemplate" and Frame2:IsA("Frame") then
			Frame2.ImageLabel.ViewportFrame.Visible = false
		end
	end
end


function UpdateToolBar(Frame)
	local PlayerInventoryEvent = game.ReplicatedStorage.Events.PlayerInventory
	local EquippedItems = PlayerInventoryEvent:InvokeServer(nil, nil,"GetEquipped")
	
	CleanToolBar(Frame)
	
	for index, Frame2 in Frame:GetChildren() do
		if Frame2.Name ~= "ItemTemplate" and Frame2:IsA("Frame") then
			if EquippedItems[index-3] ~= "Empty" then
				
				Frame2.ImageLabel.ViewportFrame.Visible = true
				
				local ItemToSend = PlayerInventoryEvent:InvokeServer(nil, tostring(EquippedItems[index-3]), "MapRawData")
				local Info = PlayerInventoryEvent:InvokeServer(nil, ItemToSend, "GetData")	
				
				local CloneViewport = Frame2.ImageLabel.ViewportFrame:Clone()
				Frame2.ImageLabel.ViewportFrame:Destroy()
				CloneViewport.Parent = Frame2.ImageLabel

				local camera = Instance.new("Camera")
				camera.Parent = Frame2.ImageLabel.ViewportFrame
				Frame2.ImageLabel.ViewportFrame.CurrentCamera = camera

				local ClonedItem = game:GetService("ReplicatedStorage").Items:WaitForChild(tostring(EquippedItems[index-3])):Clone()
				ClonedItem.Parent = Frame2.ImageLabel.ViewportFrame
				local Pos = ClonedItem.PrimaryPart.Position

				local cameraPosition = Pos + Vector3.new(0, 3, 0)
				camera.CFrame = CFrame.new(cameraPosition) * CFrame.Angles(0, math.rad(45), 0) * CFrame.new(0, 0, (cameraPosition - Pos).Magnitude)
				camera.CFrame = CFrame.lookAt(camera.CFrame.Position, Pos)
			else
				Frame2.ImageLabel.ViewportFrame.Visible = false
			end
		end
	end
end


local function InputBegan(Input, Processed)
	if Processed then return end
	local KeyCodeName = Input.KeyCode.Name
	
	local ActionIndex = table.find(Keys, KeyCodeName)
	
	if not ActionIndex then return end
	
	local Humanoid = game.Players.LocalPlayer.Character.Humanoid
	
	if LastActivated then
		if LastActivated == ToolBarFrame[KeyCodeName] then
			Global("Tween", LastActivated.ImageLabel, TweenInfo.new(.3), {ImageColor3 = Color3.fromRGB(130,130,130)})
			LastActivated = nil
			Humanoid:UnequipTools()
			return
		end
		
		
		Global("Tween", LastActivated.ImageLabel, TweenInfo.new(.3), {ImageColor3 = Color3.fromRGB(130,130,130)})
	end
	
	Global("Tween", ToolBarFrame[KeyCodeName].ImageLabel, TweenInfo.new(.3), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
	
	LastActivated = ToolBarFrame[KeyCodeName]
	
	--// Equip player weapon / tool here! @Aquatic
	
	local PlayerInventoryEvent = game.ReplicatedStorage.Events.PlayerInventory
	local EquippedItems = PlayerInventoryEvent:InvokeServer(nil, nil, "GetEquipped")
	local CurrentlyEquipped = EquippedItems[LastActivatedMapping[tostring(LastActivated)]]	
	local Backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")		
	
	if CurrentlyEquipped == "Empty" then 
		Humanoid:UnequipTools()
		return
	end
	
	pcall(function()
		if Backpack:FindFirstChild(CurrentlyEquipped) then
			Humanoid:UnequipTools()
			Humanoid:EquipTool(Backpack[CurrentlyEquipped])
		else
			warn("Item not found in Backpack:", CurrentlyEquipped)
		end
	end)

	
end

for i=1, 5 do
	local Template = ToolBarFrame.ItemTemplate:Clone()
	Template.Name = Keys[i]
	Template.Visible = true
	Template.Parent = ToolBarFrame
	Template.ItemCount.Text = i
end

Global.UserInputService.InputBegan:Connect(InputBegan)

-- Emotes

local Emotes = MainUI.Open.Emotes

local CanClick = {}

for _, Template in Emotes:GetChildren() do
	if not Template:IsA("Frame") or Template.Name == "EmoteList" then continue end
	
	local LastSize = Template.Size
	
	Template.Button.MouseButton1Click:Connect(function()
		if CanClick[Template] then return end
		
		CanClick[Template] = true
		
		task.delay(.5, function()
			CanClick[Template] = false
		end)
		
		Template.Circle.ImageColor3 = Color3.fromRGB(255,255,255)
		
		Global("Tween", Template.Circle, TweenInfo.new(.5), {ImageColor3 = Color3.fromRGB(130,130,130)})
		Global("Tween", Template, TweenInfo.new(.2), {Size = Template.Size+UDim2.new(.03,0,.05,0)})
		
		task.delay(.2, function()
			Global("Tween", Template, TweenInfo.new(.5), {Size = LastSize})
		end)
	end)
end

UpdateToolBar(ToolBarFrame)
