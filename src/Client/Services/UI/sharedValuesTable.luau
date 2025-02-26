--!strict
local ReplicatedStore = game.ReplicatedStorage
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RSLib = ReplicatedStore:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local PlayerDataFormat = require(RSLib:WaitForChild("PlayerDataDictionary"))
local BlinkClient = require(script.Parent.Parent.blinkClient)

--Libraries for gadgets and emotes :D
local GadgetFunctions = require(RSLib:WaitForChild("GadgetsDictionary"):WaitForChild("Functions"))

local SharedValuesTable = {}

type UsedAs<T> = Fusion.UsedAs<T>

export type menu = "Gadgets" | "Emotes" | "None" | "Shop"
export type loaderTweenPase = "Growing" | "Max" | "Shrinking" | "Min"

export type fusionFormatedGadgets = {string}

export type sharedValuesTable = {
	scope : Fusion.Scope,
	loaderTweenPase : Fusion.Value<loaderTweenPase>,
	
	currentViewingMenu : Fusion.Value<menu>,
	targetMenu : Fusion.Value<menu>,	--targetMenu is set before currentlyViewingMenu

	vieiwngItem : Fusion.Value<number?>,

	characterClone : Model?,
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
		if Fusion.peek(i) ~= newInput[i :: any] then
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
local function listenForChangesInEquippedItem(svt : sharedValuesTable) : nil
	local scope = svt.scope
	local menuChangeObserver = scope:Observer(svt.currentViewingMenu)
	local _menuChangeObserverDisconnect = menuChangeObserver:onChange(function()
		if svt.vieiwngItem then
			svt.vieiwngItem:set(nil)
		end
	end)
	local itemChangeObserver = scope:Observer(svt.vieiwngItem)
	local _itemChangeObserverDisconnect = itemChangeObserver:onChange(function()
		
		local itemID : number? = Fusion.peek(svt.vieiwngItem)
		print(itemID, svt.characterClone)
		if itemID ~= nil and svt.characterClone then 
			local derivedScope : Fusion.Scope = scope:deriveScope()
			local currentlyVieiwingMenu : menu = Fusion.peek(svt.currentViewingMenu) :: menu
			local IBG : GadgetFunctions.InventoryBaseGadget?
			if currentlyVieiwingMenu == "Gadgets" then
				IBG = GadgetFunctions.InventoryBaseGadget.new(svt.characterClone, itemID)
				if IBG then
					IBG:setupOnCharacter()
				end
			end

			local derivedItemChangeObserver = derivedScope:Observer(svt.vieiwngItem)
			local _derivedItemChangeObserverDisconnect = derivedItemChangeObserver:onChange(function()
				if IBG then
					IBG:deconstruct()
				end
				derivedScope:doCleanup()
			end)
		end
		
	end)
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

	result.vieiwngItem = result.scope:Value(nil)


	--functions 
	result.fetchPlayerData = function() : nil
		local fetchResult = BlinkClient.FetchPlayerData.Invoke()
		print(fetchResult)
		result.playerData = (fetchResult :: any)

		--fusion will only rerender NECISSARY COMPONENTS :D
		updateFusionTable(result.scope, result.myGadgetsFS, fetchResult.Gadgets)
		updateFusionTable(result.scope, result.equippedGadgetsFS, fetchResult.EquippedGadgets)
		updateFusionTable(result.scope, result.myEmotesFS, fetchResult.Emotes)
		updateFusionTable(result.scope, result.equippedEmotesFS, fetchResult.EquippedEmotes)
		return
	end
	

	result.fetchPlayerData()
	listenForChangesInEquippedItem(result :: any)
	return result :: any
end



return SharedValuesTable

