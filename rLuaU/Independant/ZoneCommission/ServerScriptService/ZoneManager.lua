local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneModule = require(ReplicatedStorage.Zones:WaitForChild("ZonePlus"))

local ZoneRemoteEvent = ReplicatedStorage.Zones:WaitForChild("ZoneRemoteEvent")
local ZoneFolder = workspace:WaitForChild("ContainerFolder")

local playerCurrentZone = {}

for _, zoneGroup in ipairs(ZoneFolder:GetChildren()) do
	local zone = ZoneModule.new(zoneGroup)
	local zoneName = zoneGroup.Name

	zone.playerEntered:Connect(function(player)
		if player and player:IsA("Player") then
			local oldZone = playerCurrentZone[player.UserId] or "Wilderness"
			if oldZone == zoneName then return end

			ZoneRemoteEvent:FireClient(player, {From = oldZone, To = zoneName})
			playerCurrentZone[player.UserId] = zoneName
		end
	end)

	zone.playerExited:Connect(function(player)
		if player and player:IsA("Player") then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local foundZone = nil

			for _, potentialZoneObject in ipairs(ZoneFolder:GetChildren()) do
				local potentialZone = ZoneModule.new(potentialZoneObject)
				if potentialZone:findPoint(root.Position) then
					foundZone = potentialZoneObject.Name
					break
				end
			end

			local oldZone = playerCurrentZone[player.UserId] or "Wilderness"
			local newZone = foundZone or "Wilderness"

			if oldZone ~= newZone then
				ZoneRemoteEvent:FireClient(player, {From = oldZone, To = newZone})
				playerCurrentZone[player.UserId] = newZone
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	playerCurrentZone[player.UserId] = "Wilderness"
end)

Players.PlayerRemoving:Connect(function(player)
	playerCurrentZone[player.UserId] = nil
end)
