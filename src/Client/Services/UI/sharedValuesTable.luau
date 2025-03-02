--!strict
local ReplicatedStore = game.ReplicatedStorage
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RSLib = ReplicatedStore:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local PlayerDataService = require(script.Parent.Parent:WaitForChild("PlayerDataService"))



--Libraries for gadgets and emotes :D
local GadgetFunctions = require(RSLib:WaitForChild("GadgetsDictionary"):WaitForChild("Functions"))

local SharedValuesTable = {}

type UsedAs<T> = Fusion.UsedAs<T>

export type menu = "Gadgets" | "Emotes" | "None" | "Shop"
export type loaderTweenPase = "Growing" | "Max" | "Shrinking" | "Min"

export type fusionFormatedGadgets = {string}

export type sharedValuesTable = {
	playerDataObject : PlayerDataService.PlayerDataObject,
	scope : Fusion.Scope,
	loaderTweenPase : Fusion.Value<loaderTweenPase>,
	
	currentViewingMenu : Fusion.Value<menu>,
	targetMenu : Fusion.Value<menu>,	--targetMenu is set before currentlyViewingMenu

	vieiwngItem : Fusion.Value<number?>,
	equippingItem : Fusion.Value<number?>,

	characterClone : Model?,
}


local function listenForChangesInEquippedItem(svt : sharedValuesTable) : nil
	local scope = svt.scope
	local menuChangeObserver = scope:Observer(svt.currentViewingMenu)
	local _menuChangeObserverDisconnect = menuChangeObserver:onChange(function()
		svt.vieiwngItem:set(nil)
		svt.equippingItem:set(nil)
	end)
	local itemChangeObserver = scope:Observer(svt.vieiwngItem)
	local _itemChangeObserverDisconnect = itemChangeObserver:onChange(function()
		svt.equippingItem:set(nil)
		local itemID : number? = Fusion.peek(svt.vieiwngItem)
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
	result.playerDataObject = PlayerDataService.new() --will not construct a new one if it already exists
	result.scope = result.playerDataObject.scope

	result.loaderTweenPase = result.scope:Value("Growing")
	
	result.currentViewingMenu = result.scope:Value("Shop")
	result.targetMenu = result.scope:Value("None")

	task.delay(1.5, function()
		result.currentViewingMenu:set("None")
	end)

	result.vieiwngItem = result.scope:Value(nil)
	result.equippingItem = result.scope:Value(nil)

	listenForChangesInEquippedItem(result :: any)
	return result :: any
end



return SharedValuesTable

