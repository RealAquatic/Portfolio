--[[
Create a KillParts Folder in workspace.
    Every part that will kill the player goes into this folder
]]--------


local killPartsFolder = game.Workspace:WaitForChild("KillParts")

for _, part in ipairs(killPartsFolder:GetChildren()) do
    if part:IsA("BasePart") then
      part.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
        if player then
          local humanoid = character:FindFirstChildOfClass("Humanoid")
          if humanoid then
              humanoid.Health = 0
          end
        else
          warn("Couldnt find the player!")
      end)
    end
end


