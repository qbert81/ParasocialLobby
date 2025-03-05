--!strict
--we are not using metatables for this as it is lower overhead
local HTTPService = game:GetService("HttpService")
local Guard = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("guard"))
local GamepassDictionary = require(script.Parent.GamepassDictionary)
local GadgetsDictionary = require(script.Parent.GadgetsDictionary)

--terms to recognize

local LIGHTER_GADGET_ID = 1

local PlayerDataFormat = {}
local CONFIG = {}
CONFIG.MAX_GADGETS = 6
CONFIG.MAX_EMOTES = 8

export type PlayerData = {
	--Inventory
	Gadgets : {[number] : boolean},	--indexed by number which is a gadget id and boolean is either true false or nil based off if they have the gadget
	EquippedGadgets : {[number] : number},--indexed by number which is slot and value is gadget id
	Emotes : {[number] : boolean},	--same as gadgets
	EquippedEmotes : {[number] : number},--same as equipped gadgets

	--Currency
	Bits : number,
	
	--Stats
	Wins : number,
	FastestWin : number,
	Level : number,
	Xp : number,

	--Purchases 
	GamepassDictionary : GamepassDictionary.GamepassDictionaryFormat,
	DeveloperProductPurchases : {[string] : number},	--list of ids and their quantity
}

export type InventoryCategory = "Emotes" | "Gadgets"

function PlayerDataFormat.getXPForLevel(playerData : PlayerData): number
	return math.floor(100 * (1.7 ^ (playerData.Level - 1)))
end

function PlayerDataFormat.levelup(playerData : PlayerData)
	if playerData.Xp < PlayerDataFormat.getXPForLevel(playerData) then
		return
	end
	playerData.Level += 1
	playerData.Xp = 0
end

function PlayerDataFormat.newPlayerData(): PlayerData
	local result = {
		Gadgets = {},
		
		EquippedGadgets = {},
		Emotes = {},
		EquippedEmotes = {},
		
		Bits = 555,
		
		Wins = 0,
		FastestWin = 0,
		Level = 1,
		Xp = 0,

		GamepassDictionary = {},
		DeveloperProductPurchases = {},
	}
	--give them the lighter gadget and set it as equipped
	result.Gadgets[LIGHTER_GADGET_ID] = true
	result.EquippedGadgets[1] = LIGHTER_GADGET_ID
	return result
end

local CoerceToNumber = function(value : any) : number
	value = tonumber(value)
	return Guard.Number(value)
end
PlayerDataFormat.DataInterface = {
	Gadgets = Guard.Map(Guard.Or(CoerceToNumber, Guard.Boolean), Guard.Boolean),
	EquippedGadgets = Guard.Map(CoerceToNumber, Guard.Number),
	Emotes = Guard.Map(CoerceToNumber, Guard.Boolean),
	EquippedEmotes = Guard.Map(CoerceToNumber, Guard.Number),
	
	Bits = Guard.Number,
	
	Wins = Guard.Number,
	FastestWin = Guard.Number,
	Level = Guard.Number,
	Xp = Guard.Number,
	ExtraStamina = Guard.Boolean,

	--Purchases 
	GamepassDictionary = Guard.Map(Guard.String, Guard.Boolean),
	DeveloperProductPurchases = Guard.Map(Guard.String, Guard.Number)
}

local VerifyInvCategory = function(cat : string) : InventoryCategory?
	if cat == "Emotes" or cat == "Gadgets" then
		return cat
	end
	return nil
end
	

function PlayerDataFormat.GetAvailableSlots(_playerData : PlayerData, cat : InventoryCategory) : number
	if cat == "Gadgets" then return CONFIG.MAX_GADGETS end
	if cat == "Emotes" then return CONFIG.MAX_EMOTES end
	warn("CATEGORY NOT FOUND")
	return -1
end
 
--CAN ERROR!!!!!!!
function PlayerDataFormat.EquipItem(playerData : PlayerData, itemID : number, indexToEquipAt : number, cat : string) : nil
	local invCat = VerifyInvCategory(cat)
	if invCat == nil then
		error("Invalid inventory category") 
		return
	end
	invCat = invCat :: InventoryCategory
	
	local GetAvailableSlots = PlayerDataFormat.GetAvailableSlots(playerData, invCat :: InventoryCategory)
	if indexToEquipAt <= 0 or indexToEquipAt > GetAvailableSlots then 
		error("INVALID INDEX TO EQUIP") 
		return 
	end
	local AllTable = playerData.Emotes
	local EquippedTable = playerData.EquippedEmotes
	if invCat == "Gadgets" then
		AllTable = playerData.Gadgets
		EquippedTable = playerData.EquippedGadgets
	end

	--check if we have it
	if AllTable[itemID] ~= true then
		error("Item not owned") 
		return
	end

	for i, v in EquippedTable do
		if(v) == itemID then 
			EquippedTable[i] = nil 
		end
	end 
	EquippedTable[indexToEquipAt] = itemID
	return
end

--CAN ERROR!!!!!!!
function PlayerDataFormat.PurchaseInventoryItem(playerData : PlayerData, itemID : number, cat : string) : nil
	local invCat = VerifyInvCategory(cat)
	if invCat == nil then
		error("INVENTORY CATEGORY INVALID")
		return
	end
	invCat = invCat :: InventoryCategory
	
	local ItemDictionary = GadgetsDictionary	--TODO: CHANGE THIS TO EMOTES
	local AllTable = playerData.Emotes
	if invCat == "Gadgets" then
		AllTable = playerData.Gadgets
		ItemDictionary = GadgetsDictionary
	end

	local FoundItemInDictionary = ItemDictionary[itemID]
	if FoundItemInDictionary == nil or FoundItemInDictionary.cost == nil then
		error("ITEM NOT FOUND IN DICTIONARY")
		return
	end
	local cost : number = FoundItemInDictionary.cost :: number
	--check if we have it
	if AllTable[itemID] == true then
		error("ITEM ALREADY OWNED")
		return
	end
	if cost > playerData.Bits then
		return
	end


	AllTable[itemID] = true
	playerData.Bits -= cost
	return
end


return PlayerDataFormat