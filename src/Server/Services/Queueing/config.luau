--!strict

local PlaceIDS = require(game:GetService("ReplicatedStorage").Shared.Libraries.PlaceIds)

export type QueueConfig = {
	minPlayers : number,
	maxPlayers : number,
	targetPlaceID : number,
	countdownFrom : number,
}

local QueueConfigTable : {[string] : QueueConfig} = {}

QueueConfigTable["Default"] = {
	minPlayers = 1,
	maxPlayers = 6,
	targetPlaceID = tonumber(PlaceIDS.InGame) or 0,
	countdownFrom = 15,
}

return QueueConfigTable
