--!strict
--we are not using metatables for this as it is lower overhead
local HTTPService = game:GetService("HttpService")
local Guard = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("guard"))
local GamepassDictionary = require(script.Parent.GamepassDictionary)

--terms to recognize


local LIGHTER_GADGET_ID = 1

local PlayerDataFormat = {}

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
		
		Bits = 0,
		
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

PlayerDataFormat.DataInterface = {
	Gadgets = Guard.Map(Guard.Number, Guard.Boolean),
	EquippedGadgets = Guard.Map(Guard.Number, Guard.Number),
	Emotes = Guard.Map(Guard.Number, Guard.Boolean),
	EquippedEmotes = Guard.Map(Guard.Number, Guard.Number),
	
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



return PlayerDataFormat