--!strict
--services
local ENABLED = false
if ENABLED == false then
	return {}
end
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

--modules
local PlaceIds = require(game:GetService("ReplicatedStorage").Shared.Libraries.PlaceIds)
local BlinkServer = require(script.Parent.blinkServer)
local CONFIG = require(script.config)
local TeleportManager = require(script.TeleportManager)

local HostMap: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(CONFIG.HostsMapKey)
local AssignedTeleportsMap: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(CONFIG.AssignedTeleportsMapKey)
local UserIdsSortedMap: MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(CONFIG.UserIdsSortedMapKey)



local PlayersPerGame = 2
local thisJobID: string = game.JobId
local AmILeaderVar = false

--helpers
local function shuffleTable(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end
local function AmILeader() : boolean
	local imLeader = false
	local transform = function(current)
		if not current then
			imLeader = true
			return thisJobID
		else
			if current == thisJobID then
				imLeader = true
				return current
			else
				imLeader = false
				return current
			end
		end
	end
	--update the sorted map
	HostMap:UpdateAsync(CONFIG.HostsMapFirstKey, transform, 100)
	return imLeader
end

game:BindToClose(function()
	if AmILeaderVar == true then
		local f = function(_) 
			return nil 
		end
		HostMap:UpdateAsync(CONFIG.HostsMapFirstKey, f , 100)
	end
end)

function getAllItems(map) : {CONFIG.SortedMapItem}
	-- the initial lower bound is nil which means to start from the very first item
	local exclusiveLowerBound = nil
	local accumulator : {CONFIG.SortedMapItem} = {}
	-- this loop continues until the end of the map is reached
	while true do
		-- get up to a hundred items starting from the current lower bound
		local items = map:GetRangeAsync(Enum.SortDirection.Ascending, 100, exclusiveLowerBound)
		
		local shouldBreak = false
		-- if the call returned less than a hundred items it means we've reached the end of the map
		if #items < 100 then
			shuffleTable(items)	--shuffle here so high user id player isnt being constantly cut off in the last elements that dont fill a queue
			shouldBreak = true
		end

		for _, item in items do
			table.insert(accumulator, item)
		end

		if shouldBreak then 
			break 
		end

		-- the last retrieved key is the exclusive lower bound for the next iteration
		exclusiveLowerBound = {}
		exclusiveLowerBound["key"] = items[#items].key
		exclusiveLowerBound["sortKey"] = items[#items].sortKey
	end
	
	return accumulator
end

local function run()
	while true do
		local suc, err = pcall(function()
			if AmILeader() then
				AmILeaderVar = true
				-- process the existing
				print("IM THE HOST")
	
				local allItems = getAllItems(UserIdsSortedMap)
				local curIndex = 0
				while #allItems - curIndex >= PlayersPerGame do
					local userIds = {}
					for _=1, PlayersPerGame do
						table.insert(userIds, allItems[curIndex].value)
						curIndex+=1
						UserIdsSortedMap:RemoveAsync(allItems[curIndex].key)
					end
					--teleport players send message
					local accessCode, PrivateServerId = TeleportService:ReserveServer(PlaceIds.InGame)
					print(userIds)
					local TeleportRequest: CONFIG.TeleportRequest = {
						accessCode = accessCode,
						userIds = userIds,
					}
					AssignedTeleportsMap:SetAsync(PrivateServerId, TeleportRequest, 100)
					task.wait()
				end
			end
		end)
		if err then
			warn(err)
		end
	
		task.wait(6)
	end	
end

local function Enqueue(player : Player, _)
	UserIdsSortedMap:SetAsync(tostring(player.UserId), player.UserId, 500)
	--additional logic to set attribute so the players ui reflects queieng state
end

local function Dequeue(player : Player, _)
	local didRemove = false
	local TFunc = function(old)
		if old then
			didRemove = true
		end
		return nil
	end
	UserIdsSortedMap:UpdateAsync(tostring(player.UserId), TFunc, 500)
	--additional logic to set attribute so the players ui reflects queieng state
end


if tonumber(game.PlaceId) == tonumber(PlaceIds.Lobby) then
	task.spawn(run)
	BlinkServer.Enqueue.On(Enqueue)
	BlinkServer.Dequeue.On(Dequeue)
	Players.PlayerRemoving:Connect(Dequeue)
end

TeleportManager.start()


return {}
