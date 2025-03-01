local ReplicatedStore = game.ReplicatedStorage
local Players = game:GetService("Players")
-- local Player = Players.LocalPlayer
local RSLib = ReplicatedStore:WaitForChild("Shared"):WaitForChild("Libraries")
local PlayerDataFormat = require(RSLib:WaitForChild("PlayerDataDictionary"))
local GadgetsDictionary = require(RSLib:WaitForChild("GadgetsDictionary"))

--WE USE FUSION
local Fusion = require(RSLib:WaitForChild("Fusion"))	
--we will use fusion here to keep track of our player data in scope to update things dynamically. 

local BlinkClient = require(script.Parent:WaitForChild("blinkClient"))

export type PlayerDataObject = {
	scope : Fusion.Scope,
	playerData : PlayerDataFormat.PlayerData,

	myGadgetsFS : {any : Fusion.Value<any>?},
	equippedGadgetsFS : {any : Fusion.Value<any>?},
	myEmotesFS : {any : Fusion.Value<any>?},
	equippedEmotesFS : {any : Fusion.Value<any>?},
	bits : Fusion.Value<number>?,
	
	--functions on tab change the loader starts once it becomes full it switches the tab and sets the currentlyviewingmenu to that
	fetchPlayerData : () -> nil,
	equipItem : (id : number?, idx : number, category : string) -> nil,
	purchaseInventoryItem : (id : number?, category : string) -> nil,
}
export type PlayerDataService = {
	Object : PlayerData?,
	new : (param1 : Fusion.Scope?) -> any,
}

local function constructFusionTable(scope : Fusion.Scope, input : {any}, range : {from : number, to : number}?) : {any : Fusion.Value<any>?}
	local construct = {}
	if range then
		for i = range.from, range.to do
			construct[i] = scope:Value(input[i])
		end
	else
		for i, v in input do
			construct[i] = scope:Value(v)
		end
	end
	return construct
end
local function updateFusionTable(scope : Fusion.Scope, fusionTable : {any : Fusion.Value<any>?}?, newInput : {any}) : nil
	if fusionTable == nil then return end
	for i, v in fusionTable do
		if Fusion.peek(v) ~= newInput[i :: any] then
			(v :: Fusion.Value<any>):set(newInput[i :: any])
		end
	end
	
	for i, v in newInput do
		if fusionTable[i] == nil then
			fusionTable[i] = scope:Value(v)
		end
	end
	return
end

local function updateConstructFusionTables(playerDataObject : PlayerDataObject) 
	updateFusionTable(playerDataObject.scope, playerDataObject.myGadgetsFS, playerDataObject.playerData.Gadgets)
	updateFusionTable(playerDataObject.scope, playerDataObject.equippedGadgetsFS, playerDataObject.playerData.EquippedGadgets)
	updateFusionTable(playerDataObject.scope, playerDataObject.myEmotesFS, playerDataObject.playerData.Emotes)
	updateFusionTable(playerDataObject.scope, playerDataObject.equippedEmotesFS, playerDataObject.playerData.EquippedEmotes)
	return
end

--assumes you set the playerdata in PlayerDataObject to new value before running this will propogate the changes to the "REACTIVE" values
local function UpdatePDOAfterMutation(PDO : PlayerDataObject) : nil
	local newPlayerData = PDO.playerData
	updateConstructFusionTables(PDO)
	if PDO.bits then
		PDO.bits:set(newPlayerData.Bits)
	end
	return
end

local function EquipItemAtIndex(playerDataObject : PlayerDataObject, itemID : number, indexToEquipAt : number, category : string) : string?
	local clientEquipResult = PlayerDataFormat.EquipItem(playerDataObject.playerData, itemID, indexToEquipAt, category) --changes replicate since tables are pass by ref in LUA :D
	if clientEquipResult then 
		warn(clientEquipResult)
		return clientEquipResult
	end
	UpdatePDOAfterMutation(playerDataObject)
	local fetchResult = BlinkClient.EquipItemAtIndex.Invoke(itemID, indexToEquipAt, category)
	playerDataObject.playerData = (fetchResult :: any)
	return
end

local function PurchaseInventoryItem(playerDataObject : PlayerDataObject, itemID : number, category : string) : string?
	local result = PlayerDataFormat.PurchaseInventoryItem(playerDataObject.playerData, itemID, category) --changes replicate since tables are pass by ref in LUA :D
	if result then 
		warn(result)
		return result
	end
	UpdatePDOAfterMutation(playerDataObject)
	local fetchResult = BlinkClient.PurchaseInventoryItem.Invoke(itemID, category)
	playerDataObject.playerData = (fetchResult :: any)
	return
end





local PlayerDataService : PlayerDataService = {} :: any
PlayerDataService.Object = nil

PlayerDataService.new = function(scope : Fusion.Scope?) : PlayerDataObject
	if PlayerDataService.Object then return PlayerDataService.Object :: any end
	if scope == nil then 
		scope = Fusion:scoped() 
	end
	local construct : PlayerDataObject = {} :: any
	construct.scope = scope :: Fusion.Scope
	construct.playerData = {} :: any
	construct.myGadgetsFS = constructFusionTable(construct.scope, {}, {from = 1, to = #GadgetsDictionary})
	construct.equippedGadgetsFS = constructFusionTable(construct.scope, {}, {from = 1, to = PlayerDataFormat.GetAvailableSlots(construct.playerData, "Gadgets")})
	construct.myEmotesFS = constructFusionTable(construct.scope, {})
	construct.equippedEmotesFS = constructFusionTable(construct.scope, {}, {from = 1, to = PlayerDataFormat.GetAvailableSlots(construct.playerData, "Emotes")})
	construct.bits = construct.scope:Value(0)
	construct.fetchPlayerData = function() : nil
		local fetchResult = BlinkClient.FetchPlayerData.Invoke()
		construct.playerData = (fetchResult :: any)
		UpdatePDOAfterMutation(construct)
		--fusion will only rerender NECISSARY COMPONENTS :D
		return
	end	
	construct.equipItem = function(id : number?, idx : number, category : string)
		if id then
			EquipItemAtIndex(construct, id, idx, category)
		end
		return
	end
	construct.purchaseInventoryItem = function(id : number?, category : string)
		if id then
			PurchaseInventoryItem(construct, id, category)
		end
		return
	end

	construct.fetchPlayerData()
	return construct
end

return PlayerDataService

