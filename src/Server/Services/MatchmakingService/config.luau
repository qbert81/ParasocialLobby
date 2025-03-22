--!strict
local CONFIG = {}
export type TeleportRequest = {
	accessCode : string,
	userIds : {number}
}
export type SortedMapItem = {
	key : string,
	sortKey : string,
	value : any,
}

CONFIG.AssignedTeleportsMapKey = "AssignedTeleports"
CONFIG.MessagingServiceTopic = "TeleportRequests"


CONFIG.HostsMapKey = "HostsMapKeyTest"
CONFIG.HostsMapFirstKey = "1"

CONFIG.UserIdsSortedMapKey = "UserIdsSortedMapTest"

return CONFIG