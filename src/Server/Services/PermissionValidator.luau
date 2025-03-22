-- Replace with your group ID
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local groupId = 34981941

-- Replace with the minimum rank required (e.g., 200 for "Tester")
local requiredRank = 99

game.Players.PlayerAdded:Connect(function(player)
        local playerRank = player:GetRoleInGroup(groupId)
		print(playerRank)
        if playerRank ~= "Tester" and playerRank ~= "Admin" and playerRank ~= "Owner" then
            player:Kick("You do not have the required rank to join.")
        end
end)

return {}