local types = {}

export type QueueArea = {
	part : BasePart,
	currentPlayers: NumberValue,
	maxPlayers : NumberValue,
	countdown: NumberValue,

	teleporting: BoolValue,
}

return types

