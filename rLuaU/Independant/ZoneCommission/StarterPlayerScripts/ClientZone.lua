local ZoneRemoteEvent = game.ReplicatedStorage.Zones:WaitForChild("ZoneRemoteEvent")
local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Settings = require(script.Settings)

local ZonePopupTemplate = game.ReplicatedStorage.Zones:WaitForChild("ZonePopup")
local isPopupPlaying = false

-- Fade sound utility
local function FadeSound(Sound: Sound, TargetVolume: number, Duration: number)
	if not Sound then return end
	local tweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local goal = { Volume = TargetVolume }
	local tween = TweenService:Create(Sound, tweenInfo, goal)
	tween:Play()
end

function Show(Data)
	if isPopupPlaying then
		return
	end

	isPopupPlaying = true 

	local ZonePopupClone = ZonePopupTemplate:Clone()
	ZonePopupClone.Parent = Player.PlayerGui
	local Group = ZonePopupClone.Group
	local Bar = Group.Bar

	local GroupTween = TweenService:Create(Group, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
	GroupTween:Play()
	GroupTween.Completed:Wait()

	local BarTween = TweenService:Create(Bar, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.3, 0.004)})
	BarTween:Play()
	BarTween.Completed:Wait()

	Bar.Text.Text = string.format("Leaving %s. Entering %s", Data["From"], Data["To"])

	local TextTween = TweenService:Create(Bar.Text, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

	task.wait(1)

	Hide(ZonePopupClone)
end

function Hide(ZonePopupClone)
	local Group = ZonePopupClone.Group
	local Bar = Group.Bar

	local GroupTween = TweenService:Create(Group, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
	GroupTween:Play()
	GroupTween.Completed:Wait()

	local BarTween = TweenService:Create(Bar, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0.004)})
	BarTween:Play()
	BarTween.Completed:Wait()

	ZonePopupClone:Destroy()

	isPopupPlaying = false
end

function Options(Data)
	local zoneSettings = Settings.Zones[Data]
	Player.Character:SetAttribute("Zone", Data)

	if zoneSettings and zoneSettings.skybox then
		local skyboxName = zoneSettings.skybox
		local clonedSky = game.ReplicatedStorage.Zones.Skies:FindFirstChild(skyboxName)

		if clonedSky and clonedSky:IsA("Sky") then
			local existingSky = game.Lighting:FindFirstChildOfClass("Sky")
			if existingSky then
				existingSky:Destroy()
			end

			local newSky = clonedSky:Clone()
			newSky.Parent = game.Lighting
		end
	end

	if zoneSettings and zoneSettings.BackgroundMusic then
		local BackgroundMusic = SoundService:FindFirstChild("BackgroundMusic")
		if not BackgroundMusic then
			BackgroundMusic = Instance.new("Sound")
			BackgroundMusic.Name = "BackgroundMusic"
			BackgroundMusic.Parent = SoundService
			BackgroundMusic.Looped = true
		end

		if BackgroundMusic.SoundId ~= zoneSettings.BackgroundMusic then
			FadeSound(BackgroundMusic, 0, 1)
			BackgroundMusic.SoundId = zoneSettings.BackgroundMusic
			BackgroundMusic:Play()
		end
		FadeSound(BackgroundMusic, 1, 1)
	else
		local BackgroundMusic = SoundService:FindFirstChild("BackgroundMusic")
		if BackgroundMusic then
			FadeSound(BackgroundMusic, 0, 1)
		end
	end
end

ZoneRemoteEvent.OnClientEvent:Connect(function(Data)
	task.spawn(function()
		Options(Data["To"])
	end)
	task.spawn(function()
		Show(Data)
	end)
end)
