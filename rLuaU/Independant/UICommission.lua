local ButtonFrame = script.Parent:WaitForChild("ButtonFrame")
local Tween = game:GetService("TweenService")

local Cache = {}

function CloseButton(Item)
	local Info = TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,0)
	local Frame = script.Parent:WaitForChild(Item)
	if Frame.Visible == true then
		local CloseUI = Tween:Create(Frame,Info,{Size = UDim2.new(0, 0, 0, 0)})
		CloseUI:Play()
		CloseUI.Completed:Wait()
		Frame.Visible = false
	else
		Frame.Visible = true
		local OpenUI = Tween:Create(Frame,Info,{Size = Cache[Frame]})
		OpenUI:Play()
	end
	script["Click"]:Play()
end


for _, Item in script.Parent:GetChildren() do
	if Item:IsA("ImageLabel") then
		Cache[Item] = Item.Size
		Item.Size = UDim2.fromScale(0,0)
		Item.CloseButton.MouseButton1Click:Connect(function()
			CloseButton(Item.Name)
		end)
	end	
end

for _, Item in ButtonFrame:GetChildren() do
	if Item:IsA("GuiButton") then
		Item.MouseEnter:Connect(function()
			local Info = TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,0)
			Tween:Create(Item,Info,{Size = UDim2.new(0, 65, 0, 65)}):Play()
		end)
		Item.MouseLeave:Connect(function()
			local Info = TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,0)
			Tween:Create(Item,Info,{Size = UDim2.new(0, 57, 0, 57)}):Play()
		end)
		Item.MouseButton1Click:Connect(function()
			CloseButton(Item.Name)
		end)
	end
end
