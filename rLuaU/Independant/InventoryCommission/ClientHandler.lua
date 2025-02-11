--[[

Some key features are not added into this github repo as i didnt make all of it. Ill be only including the things i have made / added onto. 
If you try to copy this, it most likely will not work.

StarterPlayer -> StarterPlayerScripts

]]

local Global = require(script.Modules.Global)

local MainUI = Global.PlayerGui:WaitForChild("MainUI")

for _, UI in MainUI.Open:GetChildren() do
	UI.Visible = false
end

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

local LastTab


local function UpdateDisplay(SelectedItem, PlayerInventoryEvent)
	local ItemInfoFrame = MainUI.Open.Inventory.ItemInfo
	local ItemName = ItemInfoFrame.ItemName
	local ItemRarity = ItemInfoFrame.ItemRarity
	local ItemText = ItemInfoFrame.InfoText

	local ItemViewPort = MainUI.Open.Inventory.ItemViewPort
	local ItemImagePlace = ItemViewPort.ImageLabel.ImageLabel
	
	local ItemToSend = tostring(SelectedItem[1]):gsub("%d+$", "")
	local Info = PlayerInventoryEvent:InvokeServer(ItemToSend, "GetData")
		
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
	
	ItemImagePlace.Image = "rbxassetid://".. Info[tostring(SelectedItem[1])]["Icon"]
	ItemImagePlace.Visible = true
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
		local PlayerInventory = PlayerInventoryEvent:InvokeServer(Name, "ReturnInventory")
		local ItemData = PlayerInventoryEvent:InvokeServer(Name, "GetData")		
				
		local function CleanInventory()
			for _, v in MainUI.Open.Inventory.ScrollingTabs[Name].ScrollingFrame:GetChildren() do
				if v:IsA("Frame") then 
					v:Destroy()
				end
			end
		end
		
		local function UpdateInventory()
			
			CleanInventory()
			
			local Slots = 18
			
			for i, v in ipairs(PlayerInventory) do
				local ItemTemplate = MainUI.Open.Inventory.ScrollingTabs.Template.ScrollingFrame.Template:Clone()
				ItemTemplate.Visible = true
				ItemTemplate.Parent = MainUI.Open.Inventory.ScrollingTabs[Name].ScrollingFrame
				ItemTemplate.Name = v
				
				if ItemData[v] then
					ItemTemplate.ImageLabel.ImageColor3 = Color3.fromRGB(130,130,130)
					ItemTemplate.ImageLabel.ImageLabel.Image = "http://www.roblox.com/asset/?id=" .. ItemData[v]["Icon"]
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
		
		UpdateInventory()
		
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


