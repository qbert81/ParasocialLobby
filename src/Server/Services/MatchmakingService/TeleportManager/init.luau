--!strict
--THIS SCRIPT SHOULD EXIST IN SERVER SERVICES OF ALL SERVERS
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local PlaceIds = require(game:GetService("ReplicatedStorage").Shared.Libraries.PlaceIds)
local CONFIG = require(script.Parent.config)

local PrivateServerId = game.PrivateServerId

local TeleportManager = {}

TeleportManager.start = function()
	if tonumber(game.PlaceId) == tonumber(PlaceIds.Lobby) then --if is lobby
		local listener = MessagingService:SubscribeAsync(
			CONFIG.MessagingServiceTopic,
			function(message: CONFIG.TeleportRequest)
				for _, userId: number in message.userIds do
					local player: Player? = Players:GetPlayerByUserId(userId)
					if player then
						local suc, err = pcall(function()
							TeleportService:TeleportToPrivateServer(PlaceIds.InGame, message.accessCode, player)
						end)
						if err then
							warn(err)
						end
					end
				end
			end
		)
	else --is in game server
		local SortedMap = MemoryStoreService:GetSortedMap(CONFIG.AssignedTeleportsMapKey)
		local acc = 0
		local max = 10
		while true do
			local read: { value: CONFIG.TeleportRequest }? = SortedMap:GetAsync(PrivateServerId)
			if read then
				local newMessage: CONFIG.TeleportRequest = {
					userIds = read.value.userIds,
					accessCode = read.value.accessCode,
				}
				SortedMap:RemoveAsync(PrivateServerId)
				MessagingService:PublishAsync(CONFIG.MessagingServiceTopic, newMessage)
				return
			end
			if acc > max then
				warn("breaking after max wait time met. No teleport request message sent")
				break
			end
			task.wait(1)
		end
	end
end

return TeleportManager
