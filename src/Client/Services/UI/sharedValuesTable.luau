local ReplicatedStore = game.ReplicatedStorage
local RSLib = ReplicatedStore:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local PlayerDataFormat = require(RSLib:WaitForChild("PlayerDataDictionary"))
local BlinkClient = require(script.Parent.Parent.blinkClient)
local SharedValuesTable = {}

type UsedAs<T> = Fusion.UsedAs<T>

export type menu = "Gadgets" | "Emotes" | "None" | "Shop"
export type loaderTweenPase = "Growing" | "Max" | "Shrinking" | "Min"

export type fusionFormatedGadgets = {string}

export type IVPair = {
	I : any,
	v : any,
}

export type sharedValuesTable = {
	scope : Fusion.Scope,
	loaderTweenPase : Fusion.Value<loaderTweenPase>,
	
	currentViewingMenu : Fusion.Value<menu>,
	targetMenu : Fusion.Value<menu>,	--targetMenu is set before currentlyViewingMenu

	viewingGadget : Fusion.Value<number>?,
	playingEmote : Fusion.Value<number>?,
	playerData : PlayerDataFormat.PlayerData,

	--formatted values for fusion to use derived from playerData
	--these are uuids
	myGadgetsFS : {any : Fusion.Value<any>?},
	equippedGadgetsFS : {any : Fusion.Value<any>?},
	myEmotesFS : {any : Fusion.Value<any>?},
	equippedEmotesFS : {any : Fusion.Value<any>?},
	
	--functions on tab change the loader starts once it becomes full it switches the tab and sets the currentlyviewingmenu to that
	fetchPlayerData : () -> nil,
}

local function constructFusionTable(scope : Fusion.Scope, input : {any}) : {any : Fusion.Value<any>?}
	local construct = {}
	for i, v in input do
		construct[i] = scope:Value(v)
	end
	return construct
end
local function updateFusionTable(scope : Fusion.Scope, fusionTable : {any : Fusion.Value<any>?}, newInput : {any}) : nil
	for i, v in fusionTable do
		if Fusion.peek(i) ~= newInput[i] then
			v:set(newInput[i])
		end
	end
	
	for i, v in newInput do
		if fusionTable[i] == nil then
			fusionTable[i] = scope:Value(v)
		end
	end
	return
end
SharedValuesTable.new = function() : sharedValuesTable
	local result = {}
	result.scope = Fusion.scoped(Fusion)
	
	--scope values
	result.playerData = {}
	result.loaderTweenPase = result.scope:Value("Growing")
	
	result.currentViewingMenu = result.scope:Value("None")
	result.targetMenu = result.scope:Value("None")

	result.myGadgetsFS = constructFusionTable(result.scope, {})
	result.equippedGadgetsFS = constructFusionTable(result.scope, {})
	result.myEmotesFS = constructFusionTable(result.scope, {})
	result.equippedEmotesFS = constructFusionTable(result.scope,{})


	--functions 
	result.fetchPlayerData = function() : nil
		local fetchResult = BlinkClient.FetchPlayerData.Invoke()
		print(fetchResult)
		result.playerData = (fetchResult)

		--fusion will only rerender NECISSARY COMPONENTS :D
		updateFusionTable(result.scope, result.myGadgetsFS, fetchResult.Gadgets)
		updateFusionTable(result.scope, result.equippedGadgetsFS, fetchResult.EquippedGadgets)
		updateFusionTable(result.scope, result.myEmotesFS, fetchResult.Emotes)
		updateFusionTable(result.scope, result.equippedEmotesFS, fetchResult.EquippedEmotes)
		return
	end

	result.fetchPlayerData()
	
	return result
end


return SharedValuesTable

