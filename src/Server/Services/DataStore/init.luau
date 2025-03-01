--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Packages = ReplicatedStorage.Packages
local DocumentService = require(Packages.documentservice)
local Guard = require(Packages.guard)
local blinkServer = require(script.Parent.blinkServer)

--player data format
local PlayerDataFormat = require(ReplicatedStorage.Shared.Libraries.PlayerDataDictionary)


local DataFetching = require(script.dataFetching)
local DataMutate = require(script.dataMutate)

type DataSchema = PlayerDataFormat.PlayerData
 
local function dataCheck(value: any): DataSchema
	assert(type(value) == "table", "Data must be a table")
    
    local formatted : {[any] : any} = {}

    for i, v in value  do
        print(i, v)
        formatted[i] = PlayerDataFormat.DataInterface[i](v)
    end
	return formatted
end
local defaultTable = PlayerDataFormat.newPlayerData()

local store : DocumentService.DocumentStore<any> = nil
if not store then
    store = DocumentService.DocumentStore.new({
        dataStore = DataStoreService:GetDataStore("TestV11") :: any,
        check = Guard.Check(dataCheck),
        default = defaultTable,
        migrations = {
            
		},
		
        lockSessions = true,
    })
end

DataFetching.init(store)
DataMutate.init(store)

--connect to Communications
blinkServer.FetchPlayerData.On(function(player: Player)
        local playerDocument : DocumentService.Document<any> = store:GetDocument(tostring(player.UserId))
        print(playerDocument)
        if playerDocument then
            local result = playerDocument:GetCache()
            print(result)
            if result then
                return result
            else
                warn("Failed to read player document: " .. result.reason)
            end
        end
    return nil
end)

return store

