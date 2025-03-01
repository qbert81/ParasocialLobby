--!strict
--this is a library of all existing gadgets

export type GadgetDetails = {
	id : number,
	name : string,
	description : string,
	rarity : number,
	cooldown : number,
}
local Gadgets : {[number] : {
	name : string,
	description : string,
	rarity : number,
	cost : number,
}} = {
	[1] = {
		name = "Lighter",
		description = "A simple lighter to help you see in the dark. It can be turned on and off.",
		rarity = 1,
		cost = 0,
	},
	[2] = {
		name = "Flashlight",
		description = "A flashlight to help you navigate dark spaces",
		rarity = 2,
		cost = 25,
	},
	[3] = {
		name = "Balloon",
		description = "A balloon to help you reach high places",
		rarity = 3,
		cost = 100,
	}
}

return Gadgets

