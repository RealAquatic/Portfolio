local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Controls = require(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerModule):GetControls()
local MainFrame = script.Parent.Main
local KeyboardSound = MainFrame.KeyboardPress
local Logo = MainFrame.Logo
local Startup = MainFrame.Startup
local WhiteFrame = MainFrame.WhiteFrame

Controls:Disable()

MainFrame.Parent.Enabled = true

function CreateWhiteFrame(Template, quantity)
	for i = 1, quantity do
		local Frame = Template:Clone()
		Frame.Position = UDim2.new(math.random(), 0, math.random(), 0)
		Frame.Parent = Template.Parent
		Frame.Visible = true
		wait(0.1)
		Frame:Destroy()
	end
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

for i = 1, #MainFrame.Text:GetChildren() do
	local textLabel = MainFrame.Text["Text"..i]
	if textLabel.ClassName == "TextLabel" then
		textLabel.Visible = true
		KeyboardSound.TimePosition = math.random((math.random(1,3)), math.floor(KeyboardSound.TimeLength))
		KeyboardSound:Play()
	end
	wait(math.random(0, (math.random(0,1))))
	
end
KeyboardSound:Stop()

wait(1)

for _,item in MainFrame.Text:GetChildren() do
	item.Visible = false
	wait()
end

Startup:Play()
wait(0.5)
Logo.Visible = true
wait(0.8)
Logo.Visible = false
CreateWhiteFrame(WhiteFrame, 6)
wait(0.5)

Logo.ImageTransparency = 1
local fadeTween = TweenService:Create(Logo, TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
Logo.Size = UDim2.new(0.155,0, 0.275,0)
Logo.Visible = true

wait(1)

local fadeTween = TweenService:Create(MainFrame, TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
wait(0.5)
Controls:Enable()
local fadeTween = TweenService:Create(Logo, TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
wait(2)
MainFrame.Parent.Enabled = false



