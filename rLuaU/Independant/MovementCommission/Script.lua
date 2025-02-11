local plr = game.Players.LocalPlayer
local Character = plr.Character or plr.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart: BasePart = Character:WaitForChild("HumanoidRootPart")


local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TouchGui = plr:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
local Camera = workspace.CurrentCamera


local ledgeavailable = true
local holding = false

--[[
COMPLETED:
SPRINTING
DASHING
SNEAKING
LEDGEHOLD
CRAWLING
GLIDING
CHARGEDJUMP

]]

local ActiveState = {
	["Dash"] = false;
	["Swimming"] = false;
	["ChargedJump"] = false;
	["Sprinting"] = false;
	["Crawling"] = false;
	["Sneaking"] = false;
	["Gliding"] = false;
	["Falling"] = false;
	["Holding"] = false;
}

local Settings = {
	originalSpeed = Humanoid.WalkSpeed;
	originalMinCameraDistance = plr.CameraMinZoomDistance;
	originalMaxCameraDistance = plr.CameraMaxZoomDistance;
	defaultFieldOfView = 70;
	
	Dash = {
		DashPower = 50,
		DashDuration = 0.8,
		Cooldown = 3,
	};
	
	Sprinting = {
		SprintSpeed = 32,
		NormalSpeed = 16
	};
	
	Sneak = {
		newSpeed = 5;
		DefaultFieldOfView = 70;
		CrouchFieldOfView = 60;
		MinCameraDistance = 0.5;
		MaxCameraDistance = 10;
		maxFreefallDuration = 0.35;
	};
	
	Crawling = {
		newSpeed = 3;
		DefaultFieldOfView = 70;
		CrawlFieldOfView = 60;
		MinCameraDistance = 0.5;
		MaxCameraDistance = 10;
	};
	
	Gliding = {
		FloatForce = 4.6;
		GliderModel = script.Info.Gliding.Glider
		
	};
	
	ChargedJump = {
		Charge = 1;
		MaxCharge = 3.5;
		Force = 250;
		ForwardForce = 300;
		Cooldown = 0.5;
		debounce = false;
		TapThreshold = 0.2;
		KeyPressStart = nil;
		KeyPressDuration = nil;
		
	};
	
	Swimming = {
		Acceleration = Vector3.new(0, 0, 0);
		Speed = 10;
		MaxSpeed = 20;
		Resistance = 0.05;
		JumpPower = 0;
		JumpResistance = 0.05;
		WaterDrag = 0.5;
		WaterTransparency = 0.5;
	}
	
}

local Sounds = {
	Crouch = script.Info.Sneaking.Crouch;
	GetUp = script.Info.Sneaking.GetUp;
	Walking = script.Info.Sneaking.Walking;
	
}

local Animations = {
	Dash = Humanoid:LoadAnimation(script.Info.Dashing.Roll);
	AirRoll = Humanoid:LoadAnimation(script.Info.Dashing.AirDash);
	Sprinting = Humanoid:LoadAnimation(script.Info.Sprinting.Sprinting);
	SneakCrouch = Humanoid:LoadAnimation(script.Info.Sneaking.Crouching);
	SneakProwling = Humanoid:LoadAnimation(script.Info.Sneaking.Prowling);
	ClimbAnim = Humanoid:LoadAnimation(script.Info.Ledgehold.ClimbAnim);
	ClimbHold = Humanoid:LoadAnimation(script.Info.Ledgehold.HoldAnim);
	CrawlIdle = Humanoid:LoadAnimation(script.Info.Crawling.CrawlIdle);
	CrawlWalk = Humanoid:LoadAnimation(script.Info.Crawling.CrawlWalk);
	Glide = Humanoid:LoadAnimation(script.Info.Gliding.GlideAnim);
	ChargedJump = Humanoid:LoadAnimation(script.Info.ChargedJump.Charge);
	ReleaseJump = Humanoid:LoadAnimation(script.Info.ChargedJump.Release);
	TapJump = Humanoid:LoadAnimation(script.Info.ChargedJump.Tap);
	SwimmingIdle = Humanoid:LoadAnimation(script.Info.Swimming.SwimingIdle)
}

function CoolDown(Item)
	task.delay(Settings[Item]["Cooldown"], function()
		ActiveState[Item] = false
	end)
end

function AddForce(inAir)
	if not HumanoidRootPart then return end

	local Bv = Instance.new("BodyVelocity")
	Bv.Parent = HumanoidRootPart
	Bv.MaxForce = Vector3.one * math.huge
	Bv.Velocity = HumanoidRootPart.CFrame.LookVector * Settings.Dash.DashPower
	PreventRotation()
	if inAir then
		Debris:AddItem(Bv, Settings.Dash.DashDuration/2)
	else
		Debris:AddItem(Bv, Settings.Dash.DashDuration)

	end
end

function PreventRotation(inAir)
	Humanoid.AutoRotate = false
	local CD = Settings.Dash.DashDuration
	if inAir then
		CD = CD / 2
	end
	task.delay(CD, function()
		Humanoid.AutoRotate = true
	end)
end



--[[

DASH

]]

function Dash()
	if ActiveState["Dash"] or ActiveState["Sneaking"] or ActiveState["Crawling"] or ActiveState["Swimming"] then return end 
	if (script.Info.Dashing.CanDash.Value) then
		local Animation = Animations.Dash
		local isAirDash = (Humanoid.FloorMaterial == Enum.Material.Air)

		if isAirDash then
			Animation = Animations.AirRoll
		end

		StopSprint()
		Animation:Play()

		AddForce(isAirDash)
		
		ActiveState["Dash"] = true
		task.spawn(CoolDown, "Dash")

		if isAirDash then
			task.wait(Settings.Dash.DashDuration/2)
		else
			task.wait(Settings.Dash.DashDuration)
		end
		Animation:Stop()
	else return end
end


--[[

SPRINT

]]


function StartSprint()
	if not ActiveState["Sprinting"] and not ActiveState["Sneaking"] then
		ActiveState["Sprinting"] = true
		Humanoid.WalkSpeed = Settings.Sprinting.SprintSpeed
		if not Animations.Sprinting.IsPlaying then
			Animations.Sprinting:Play()
		end
	end
end

function StopSprint()
	if ActiveState["Sprinting"] then
		ActiveState["Sprinting"] = false
		Humanoid.WalkSpeed = Settings.Sprinting.NormalSpeed
		if Animations.Sprinting.IsPlaying then
			Animations.Sprinting:Stop()
		end
	end
end


--[[

SNEAKING

]]

function Tween(object, properties, duration, easingStyle)
	TweenService:Create(object, TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Linear), properties):Play()
end

function ToggleHighlight(state)
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= plr and player.Character then
			local highlight = player.Character:FindFirstChild("PlayerHighlight")
			if state then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "PlayerHighlight"
					highlight.FillColor = Color3.new(1, 1, 1)
					highlight.FillTransparency = 0.5
					highlight.OutlineTransparency = 1
					highlight.Parent = player.Character
				end
			else
				highlight:Destroy()
			end
		end
	end
end

local colorEffect = Instance.new("ColorCorrectionEffect")
colorEffect.TintColor = Color3.new(0.423529, 0.423529, 0.423529)
colorEffect.Brightness = 0.3
colorEffect.Saturation = -1
colorEffect.Enabled = false
colorEffect.Parent = Lighting

function Crouch()
	if not ActiveState["Sneaking"] and Humanoid.FloorMaterial ~= Enum.Material.Air and script.Info.Sneaking:FindFirstChild("CrouchEnabled").Value and not ActiveState["Crawling"] then
		script.Info.Dashing.CanDash.Value = false
		ActiveState["Sneaking"] = true
		Animations.SneakCrouch.Looped = true
		Animations.SneakCrouch:Play()
		Animations.SneakProwling.Looped = true
		if Sounds.Crouch then Sounds.Crouch:Play() end
		Humanoid.WalkSpeed = Settings.Sneak.newSpeed
		plr.CameraMinZoomDistance = Settings.Sneak.MinCameraDistance
		plr.CameraMaxZoomDistance = Settings.Sneak.MaxCameraDistance
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		colorEffect.Enabled = true
		ToggleHighlight(true)

		Tween(Camera, { FieldOfView = Settings.Sneak.CrouchFieldOfView }, 0.5)
		Tween(Humanoid, { CameraOffset = Vector3.new(0, -1, 0) }, 0.3, Enum.EasingStyle.Back)
	end
end

function CanUnsneak()
	local head = Character:FindFirstChild("Head")
	if head then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { Character }
		local result = workspace:Raycast(head.Position, head.CFrame.UpVector * 1.5, rayParams)
		return result == nil
	end
	return true
end

function StopSneaking()
	if ActiveState["Sneaking"] and CanUnsneak() then
		script.Info.Dashing.CanDash.Value = true
		ActiveState["Sneaking"] = false
		Animations.SneakCrouch.Looped = false
		Animations.SneakCrouch:Stop()
		Animations.SneakProwling.Looped = false
		Animations.SneakProwling:Stop()
		if Sounds.GetUp then Sounds.GetUp:Play() end
		Humanoid.WalkSpeed = Settings.originalSpeed
		plr.CameraMinZoomDistance = Settings.originalMinCameraDistance
		plr.CameraMaxZoomDistance = Settings.originalMaxCameraDistance
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		colorEffect.Enabled = false
		ToggleHighlight(false)

		Tween(Camera, { FieldOfView = Settings.Sneak.DefaultFieldOfView }, 0.5)
		Tween(Humanoid, { CameraOffset = Vector3.new(0, 0, 0) }, 0.3, Enum.EasingStyle.Back)
	end
end

--[[

LEDGEHOLD

]]


function climb()
	local Vele = Instance.new("BodyVelocity", HumanoidRootPart)
	HumanoidRootPart.Anchored = false
	Vele.MaxForce = Vector3.new(1, 1, 1) * math.huge
	Vele.Velocity = HumanoidRootPart.CFrame.LookVector * 10 + Vector3.new(0, 30, 0)
	Animations.ClimbHold:Stop()
	Animations.ClimbAnim:Play()
	game.Debris:AddItem(Vele, .15)

	ActiveState["Holding"] = false
	ledgeavailable = true

	wait(.75)
end

function LedgeHold()
	local r = Ray.new(plr.Character.Head.CFrame.p, plr.Character.Head.CFrame.LookVector * 2.5)
	local part,position = workspace:FindPartOnRay(r,Character)

	if part and ledgeavailable and not ActiveState["Holding"] and not ActiveState["Dash"] then
		if part:IsA("Terrain") or part:IsA("BasePlate") then return end
		if part.Size.Y >= 7 then
			if plr.Character.Head.Position.Y >= (part.Position.Y + (part.Size.Y / 2)) - 1 or plr.Character.Head.Position.Y <= part.Position.Y + (part.Size.Y / 2) and Humanoid.FloorMaterial == Enum.Material.Air then
				HumanoidRootPart.Anchored = true 
				ActiveState["Holding"] = true 
				Animations.ClimbHold:Play() 
				ledgeavailable = false
			end
		end
	end
end


--[[

Crawling

]]

function StartCrawling()
	if not ActiveState["Crawling"] and Humanoid.FloorMaterial ~= Enum.Material.Air and not ActiveState["Sneaking"] then
		ActiveState["Crawling"] = true
		Animations.CrawlIdle.Looped = true
		Animations.CrawlIdle:Play()
		Animations.CrawlWalk.Looped = true
		Animations.CrawlWalk:Play()
		Humanoid.WalkSpeed = Settings.Crawling.newSpeed
		plr.CameraMinZoomDistance = Settings.Crawling.MinCameraDistance
		plr.CameraMaxZoomDistance = Settings.Crawling.MaxCameraDistance
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		Tween(Camera, { FieldOfView = Settings.Crawling.CrawlFieldOfView }, 0.5)
		Tween(Humanoid, { CameraOffset = Vector3.new(0, -1, 0) }, 0.3, Enum.EasingStyle.Back)
	end
end

function CanUncrawl()
	local head = Character:FindFirstChild("Head")
	if head then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { Character }
		local result = workspace:Raycast(head.Position, head.CFrame.UpVector * 3, rayParams)
		return result == nil
	end
	return true
end

function StopCrawling()
	if ActiveState["Crawling"] and CanUncrawl() then
		ActiveState["Crawling"] = false
		Animations.CrawlIdle.Looped = false
		Animations.CrawlIdle:Stop()
		Animations.CrawlWalk.Looped = false
		Animations.CrawlWalk:Stop()
		Humanoid.WalkSpeed = Settings.originalSpeed
		plr.CameraMinZoomDistance = Settings.originalMinCameraDistance
		plr.CameraMaxZoomDistance = Settings.originalMaxCameraDistance
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		Tween(Camera, { FieldOfView = Settings.defaultFieldOfView }, 0.5)

		Tween(Humanoid, { CameraOffset = Vector3.new(0, 0, 0) }, 0.3, Enum.EasingStyle.Back)
	end
end

--[[

GLIDING

]]

function startGliding()
	if not ActiveState["Gliding"] and not ActiveState["Sprinting"] and not ActiveState["Holding"] then
		ActiveState["Gliding"] = true

		if not HumanoidRootPart:FindFirstChild("GlideForce") then
			local glideForce = Instance.new("BodyVelocity")
			glideForce.Name = "GlideForce"
			glideForce.MaxForce = Vector3.new(0, 100000, 0)
			glideForce.Velocity = Vector3.new(0, -10, 0)
			glideForce.Parent = HumanoidRootPart
			Animations.Glide:Play(0.1)
		end

		if not Settings.Gliding.GliderModel then
			Settings.Gliding.GliderModel = workspace:FindFirstChild("Glider")
			if Settings.Gliding.GliderModel and Settings.Gliding.GliderModel:IsA("Model") then
				local gliderPrimaryPart = Settings.Gliding.GliderModel.PrimaryPart
				if gliderPrimaryPart then
					Settings.Gliding.GliderModel:SetPrimaryPartCFrame(CFrame.new(HumanoidRootPart.Position - Vector3.new(0, 3, 0)))
					for _, desc in ipairs(Settings.Gliding.GliderModel:GetDescendants()) do
						if desc:IsA("BasePart") then
							desc.CanCollide = false
							desc.Transparency = 0
						end
					end
				else
					warn("Glider Model has no PrimaryPart set!")
				end
			else
				warn("Glider Model not found in the workspace!")
			end
		end

	end
end


function EndGliding()
	if ActiveState["Gliding"] then
		ActiveState["Gliding"] = false

		if HumanoidRootPart:FindFirstChild("GlideForce") then
			HumanoidRootPart.GlideForce:Destroy()
			Animations.Glide:Stop()
		end

		if Settings.Gliding.GliderModel then
			for _, desc in ipairs(Settings.Gliding.GliderModel:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Transparency = 1
					desc.CanCollide = false
				end
			end
			Settings.Gliding.GliderModel = nil
		end

	end
end

--[[

CHARGED JUMP

]]

function SetStun(Stun)
	if Stun then
		Humanoid.JumpPower = 50
		Humanoid.JumpHeight = 7.2
		Humanoid.WalkSpeed = 10
	else
		Humanoid.JumpPower = 0
		Humanoid.JumpHeight = 0
		Humanoid.WalkSpeed = 0
	end
end

function Jump()
			
	if ActiveState["Swimming"] then return end
	
	if ActiveState["Holding"] then
		Animations.ClimbHold:Stop()
		HumanoidRootPart.Anchored = false
		HumanoidRootPart:ApplyImpulse((-HumanoidRootPart.CFrame.LookVector * 50) + Vector3.new(0, 300, 0) * 3)
		ActiveState["Holding"] = false
		task.wait(0.4)
		ledgeavailable = true
		return	
	end
	
	if (Settings.ChargedJump.KeyPressDuration or 0) < Settings.ChargedJump.TapThreshold and not ActiveState["ChargedJump"] then
		ActiveState["ChargedJump"] = true
		Animations.TapJump:Play()
		HumanoidRootPart:ApplyImpulse(Vector3.new(0, 250, 0))
		task.wait(0.8)
		CoolDown("ChargedJump")
	elseif not ActiveState["ChargedJump"] and not ActiveState["Swimming"] then
		ActiveState["ChargedJump"] = true
		SetStun(false)
		Animations.ChargedJump:Play()
		while UIS:IsKeyDown(Enum.KeyCode.Space) and Settings.ChargedJump.Charge < Settings.ChargedJump.MaxCharge do
			Settings.ChargedJump.Charge += 0.3
			task.wait(0.1)
		end
		Animations.ChargedJump:Stop()
		SetStun(true)
		Animations.ReleaseJump:Play()
		HumanoidRootPart:ApplyImpulse(Vector3.new(0, Settings.ChargedJump.Force * Settings.ChargedJump.Charge, 0))
		HumanoidRootPart:ApplyImpulse(HumanoidRootPart.CFrame.LookVector * (Settings.ChargedJump.ForwardForce * Settings.ChargedJump.Charge))

		repeat task.wait() until not Animations.ReleaseJump.IsPlaying
		Settings.ChargedJump.Charge = 1
		CoolDown("ChargedJump")

	end

	SetStun(true)
end



--[[

SWIMMING

]]


function Swim()
	ActiveState["Swimming"] = true
	if Animations.SwimmingIdle.IsPlaying then 
		return 
	else
		Animations.SwimmingIdle:Play()
	end	
end

function SwimStop()
	ActiveState["Swimming"] = false
	if Animations.SwimmingIdle.IsPlaying then 
		Animations.SwimmingIdle:Stop()
	end
end


--[[


INPUTS


]]


UIS.InputBegan:Connect(function(inp, proc)
	if proc then return end
	if inp.KeyCode == Enum.KeyCode.Q then
		if ActiveState["Holding"] then return end
		Dash()
	elseif inp.KeyCode == Enum.KeyCode.LeftShift and (IsInMotion() > 1) and not ActiveState["Sneaking"] and not ActiveState["Crawling"] then
		StartSprint()
	elseif inp.KeyCode == Enum.KeyCode.C then
		StopSprint()
		if ActiveState["Sneaking"] then
			if CanUnsneak() then
				StopSneaking()
			end
		else
			Crouch()
		end
	elseif inp.KeyCode == Enum.KeyCode.Space then -- StopSneak Stop Sprint Stop Crawl
		
		if ActiveState["Sprinting"] then
			StopSprint()
		end
		if ActiveState["Sneaking"] then
			StopSneaking()
		end
		if ActiveState["Crawling"] then
			StopCrawling()
		end
		if ActiveState["Gliding"] then
			EndGliding()
		end
				
	elseif inp.KeyCode == Enum.KeyCode.X then -- Crawl
		if ActiveState["Crawling"] then
			StopCrawling()
		else
			if ActiveState["Sprinting"] then
				StopSprint()
			end
			StartCrawling()
		end
	elseif inp.KeyCode == Enum.KeyCode.G then
		if ActiveState["Gliding"] then
			EndGliding()
		elseif ActiveState["Falling"] then
			startGliding()
		end	
	end	
end)

UIS.InputBegan:Connect(function(Key,Chat)
	if not holding then return end 
	if Key.KeyCode == Enum.KeyCode.Space and not Chat then
		climb()
	end
end)

UIS.InputEnded:Connect(function(Key, Proc)
	if Proc then return end
	if Key.KeyCode == Enum.KeyCode.Space then
		if ActiveState["Holding"] then
			Settings.ChargedJump.KeyPressStart = nil
			return
		else
			pcall(function()
				Settings.ChargedJump.KeyPressDuration = (os.clock() - Settings.ChargedJump.KeyPressStart)
				Settings.ChargedJump.KeyPressStart = nil
			end)
		end
	end
	
end)

UIS.JumpRequest:Connect(function()
	if Humanoid:GetState() == Enum.HumanoidStateType.Swimming then Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) 
	else 	
		if not ActiveState["ChargedJump"] and not IsInAir() then
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			Settings.ChargedJump.KeyPressStart = os.clock()
			Jump()
		else
			if ActiveState["Holding"] then Jump() else Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end	
		end
	end
end)


function IsInAir()
	return Humanoid:GetState() == Enum.HumanoidStateType.Jumping or Humanoid:GetState() == Enum.HumanoidStateType.Freefall
end

function IsInMotion()
	return HumanoidRootPart.AssemblyLinearVelocity.Magnitude
end

function IsSwimming()
	if Humanoid:GetState() == Enum.HumanoidStateType.Swimming  then
		ActiveState["Swimming"] = true
		Swim()
		return true
	else
		ActiveState["Swimming"] = false
		SwimStop()
		return nil
	end
end

UIS.InputEnded:Connect(function(inp, proc)
	if proc then return end
	if inp.KeyCode == Enum.KeyCode.LeftShift then
		StopSprint()
	end
end)

RunService.Heartbeat:Connect(function()
	local IsInAir = IsInAir()
	local IsInMotion = IsInMotion()
	local IsSwimming = IsSwimming()
	if IsInAir or IsSwimming then
		ActiveState["Falling"] = true
		StopCrawling()
		StopSneaking()
		StopSprint()
	else
		ActiveState["Falling"] = false
		
		if ActiveState["Gliding"] then
			EndGliding()
		end
	end
	if IsInMotion < 1 then
		StopSprint()
	end
	if ActiveState["Sneaking"] then
		if (IsInMotion < 1) then
			if not Animations.SneakCrouch.IsPlaying then 
				Animations.SneakCrouch:Play()
			end
			Animations.SneakProwling:Stop()
		else
			if not Animations.SneakProwling.IsPlaying then
				Animations.SneakProwling:Play()
			end
			Animations.SneakCrouch:Stop()
		end
	end
	if ActiveState["Crawling"] then
		if (IsInMotion < 1) then
			if not Animations.CrawlIdle.IsPlaying then
				Animations.CrawlIdle:Play()
			end
			Animations.CrawlWalk:Stop()
		else
			if not Animations.CrawlWalk.IsPlaying then
				Animations.CrawlWalk:Play()
			end
			Animations.CrawlIdle:Stop()
		end
	end
	
	if not IsSwimming then
		LedgeHold()
	end


	if not ActiveState["Falling"] and ActiveState["Gliding"] then
		EndGliding()
	end
end)
