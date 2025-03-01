--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local blinkServer = require(script.Parent.Parent.blinkServer)

local Packages = ReplicatedStorage.Packages
local DocumentService = require(Packages.documentservice)
local Guard = require(Packages.guard)

--player data format
local PlayerDataFormat = require(ReplicatedStorage.Shared.Libraries.PlayerDataDictionary)
local dataMutate = {}

local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value) -- Recursively clone sub-tables
		else
			copy[key] = value
		end
	end
	return copy
end
--mutate function should ALWAYS be a pcall
local function mutateDocument(
	store : DocumentService.DocumentStore<any>, 
	player : Player, 
	mutateFunction : (playerDataObject : PlayerDataFormat.PlayerData) -> PlayerDataFormat.PlayerData?
) : PlayerDataFormat.PlayerData?
	
	local playerDocument: DocumentService.Document<any> = store:GetDocument(tostring(player.UserId))
	if playerDocument then
		if not playerDocument:IsOpen() then
			return
		end
		
		-- Clone the table and any sub-tables we intend to edit
		print(playerDocument:GetCache())
		local playerDataClone = deepCopy(playerDocument:GetCache())
		print(playerDataClone)
		local success, err = pcall(function()
			mutateFunction(playerDataClone :: any)
		end)

		if not success then
			warn("Error in mutateFunction: " .. tostring(err))
			return playerDocument:GetCache() -- Return existing cache if mutation fails
		end

		-- Save the mutated data
		playerDocument:SetCache(playerDataClone)
		print(playerDocument:GetCache())
		return playerDataClone
	end
	return nil
end

--listens to remote for data mutation requests
function dataMutate.init(store: DocumentService.DocumentStore<any>)
	blinkServer.PurchaseInventoryItem.On(function(player: Player, itemID : number, cat : string)
		local _mutateFunc = function(playerDataObject : PlayerDataFormat.PlayerData)
			PlayerDataFormat.PurchaseInventoryItem(playerDataObject, itemID, cat)
		end
		local afterMutation = mutateDocument(store, player, _mutateFunc)
		return afterMutation
	end)
	blinkServer.EquipItemAtIndex.On(function(player: Player, itemID : number, indexToEquipAt: number, cat : string)
		local _mutateFunc = function(playerDataObject : PlayerDataFormat.PlayerData)
			PlayerDataFormat.EquipItem(playerDataObject, itemID, indexToEquipAt, cat)
		end
		local afterMutation = mutateDocument(store, player, _mutateFunc)
		return afterMutation
	end)
end

return dataMutate
