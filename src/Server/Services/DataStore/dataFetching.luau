--!strict
local DocumentService = require(game:GetService("ReplicatedStorage").Packages.documentservice)
local documentFetching = {}

local function playerAdded(store : DocumentService.DocumentStore<any>, player : Player) : boolean
	local document = store:GetDocument(tostring(player.UserId))
	local result = document:Open()
	-- DocumentService retries 5 times over 16 seconds, so it is safe to steal
	-- after a failed `:Open`!
	if not result.success and result.reason == "SessionLockedError" then
		document:Steal()
		result = document:Open()
	end
	if not result.success then
		if result.reason == "BackwardsCompatibilityError" then
			player:Kick(
				"You joined an old server which does not support your saved data."
					.. "Please try joining another server. If this persists, contact a developer."
			)
		end

		if result.reason == "RobloxAPIError" then
			player:Kick("Failed to load data due to a Roblox service issue. Try again later.")
		end

		player:Kick(
			`Failed to load data: {result.reason}. Please screenshot this message and report it to a developer.`
		)

		return false
	 end
	 return true
end

local function playerRemoving(store : DocumentService.DocumentStore<any>, player : Player) : nil
	local key : string = tostring(player.UserId)
	local document = store:GetDocument(key)
	print(document:GetCache())
	if document:IsOpen() then
		local suc, err = pcall(function()
			document:Close()
			print("RAN")
		end)
		if err then
			warn(err)
		else
			print(suc)
		end
	end
	return
end

documentFetching.init = function(store : DocumentService.DocumentStore<any>)
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player)
		playerAdded(store, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		playerRemoving(store, player)
	end)

end


return documentFetching