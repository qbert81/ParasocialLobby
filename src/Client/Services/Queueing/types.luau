local types = {}

export type QueueArea = {
	part : BasePart,
	currentPlayers: NumberValue,
	countdown: NumberValue,

	teleporting: BoolValue,
}

return types

