--!strict
local RSLib = game:GetService("ReplicatedStorage").Shared.Libraries
local Tags = require(RSLib.Tags)
local QueueConfig = require(script.config)
local TeleportService = game:GetService("TeleportService")
local blinkServer = require(script.Parent.blinkServer)
local CLS = game:GetService("CollectionService")
--When a player joins the countdown starts

export type QueueingArea = { --QueueingAreas are identified by their unique basepart
	part: BasePart,

	--from config : searched by part name yuh
	config: QueueConfig.QueueConfig,

	--storing current values
	currentPlayersList: { [Player]: boolean? }, --use table.insert or table.remove so we can use # table opperator
	currentPlayersNumber: number,

	numberValues: {
		currentPlayers: NumberValue,
		countdown: NumberValue,
	},

	teleporting: BoolValue,
	teleported : boolean,

	EnqueuePlayer: (QueueingArea, Player) -> boolean, --returns success	| not exposed to client see upper level class
	DequeuePlayer: (QueueingArea, Player) -> boolean, --returns success	| not exposed to client see upper level class
}

export type QueueingSystem = {
	Running: boolean,

	PlayersWaitingToEnqueue: { [Player]: BasePart },
	PlayersWaitingToDequeue: { [Player]: boolean },

	PlayersEnqueued: { [Player]: BasePart }, --index by BP for efficient lookup times
	QueueingAreas: { [BasePart]: QueueingArea },

	ProcessPending: (QueueingSystem) -> nil,
	EnqueuePlayer: (QueueingSystem, Player, BasePart) -> boolean, --returns success
	DequeuePlayer: (QueueingSystem, Player, BasePart) -> boolean, --returns success
	Start: (QueueingSystem) -> nil,
}

--QUEUEING AREA -------------------------------------------
local QueueingArea = {}
QueueingArea.__index = QueueingArea

function QueueingArea.new(part: BasePart)
	local self: QueueingArea = setmetatable({}, QueueingArea) :: any

	local configFound: QueueConfig.QueueConfig? = QueueConfig[part.Name]
	if configFound == nil then
		configFound = QueueConfig.Default
	end

	self.config = configFound :: QueueConfig.QueueConfig

	self.part = part
	CLS:AddTag(part, Tags.CLS.QueuingArea)
	self.currentPlayersList = {}
	self.currentPlayersNumber = #self.currentPlayersList

	local function createNumberValue(name: string): NumberValue
		local nv = Instance.new("NumberValue")
		nv.Name = name
		nv.Parent = self.part
		return nv
	end

	--booleans
	self.teleporting = Instance.new("BoolValue")
	self.teleporting.Name = "Teleporting"
	self.teleporting.Value = false
	self.teleporting.Parent = self.part
	self.teleported = false

	self.numberValues = {
		countdown = createNumberValue("Countdown"),
		currentPlayers = createNumberValue("CurrentPlayers"),
	}

	return self
end

function QueueingArea:EnqueuePlayer(Player: Player): boolean
	self = self :: QueueingArea
	if self.teleporting.Value == true then
		return false
	end
	self.currentPlayersList[Player] = true
	self.currentPlayersNumber += 1
	self.numberValues.currentPlayers.Value = self.numberValues.currentPlayers.Value + 1
	if self.currentPlayersNumber >= self.config.maxPlayers then
		self.teleporting.Value = true
	end
	return true
end

function QueueingArea:DequeuePlayer(Player: Player): boolean
	self = self :: QueueingArea
	if self.currentPlayersList[Player] then
		self.currentPlayersList[Player] = nil
		self.currentPlayersNumber -= 1
		self.numberValues.currentPlayers.Value = self.numberValues.currentPlayers.Value - 1
		if self.currentPlayersNumber == 0 then
			self.teleporting.Value = false
		end
	end
	return true
end

--QUEUEING SYSTEM -------------------------------------------
local QueueingSystem = {}
QueueingSystem.__index = QueueingSystem
function QueueingSystem.new()
	local self: QueueingSystem = setmetatable({}, QueueingSystem) :: any
	self.PlayersWaitingToEnqueue = {}
	self.PlayersWaitingToDequeue = {}
	self.PlayersEnqueued = {}
	self.QueueingAreas = {}

	local function RegisterQueuingArea(part: BasePart)
		self.QueueingAreas[part] = QueueingArea.new(part)
	end

	for i, v in game.Workspace.QueueingAreas:GetChildren() do
		if v:IsA("BasePart") then
			RegisterQueuingArea(v)
		end
	end

	game.Workspace.QueueingAreas.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			RegisterQueuingArea(child)
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		local bp: BasePart? = self.PlayersEnqueued[player]
		if bp then
			self:DequeuePlayer(player, bp)
		end
	end)
	
	blinkServer.Enqueue.On(function(player : Player, basepart : Instance)
		if basepart:IsA("BasePart") then
			self.PlayersWaitingToEnqueue[player] = basepart
		end
		return
	end)

	blinkServer.Dequeue.On(function(player : Player, basepart : Instance)
		if basepart:IsA("BasePart") then
			self.PlayersWaitingToDequeue[player] = true
		end
		return
	end)
	
	self:Start()
	return self
end

function QueueingSystem:EnqueuePlayer(player : Player, basePart : BasePart)
	self = self :: QueueingSystem
	local qa : QueueingArea = self.QueueingAreas[basePart]
	local result = qa:EnqueuePlayer(player)
	if result == true then
		self.PlayersEnqueued[player] = basePart
	end
end
function QueueingSystem:DequeuePlayer(player : Player, basePart : BasePart)
	self = self :: QueueingSystem
	local qa : QueueingArea = self.QueueingAreas[basePart]
	local result = qa:DequeuePlayer(player)
	if result == true then
		self.PlayersEnqueued[player] = nil
	end
end

function QueueingSystem:ProcessPending()
	self = self :: QueueingSystem
	for player, BasePart in self.PlayersWaitingToEnqueue do
		self:EnqueuePlayer(player, BasePart)
	end
	self.PlayersWaitingToEnqueue = {}
	for player, boolean in self.PlayersWaitingToDequeue do
		local bp: BasePart? = self.PlayersEnqueued[player]
		if bp then
			self:DequeuePlayer(player, bp)
		end
	end
	self.PlayersWaitingToDequeue = {}
end

local dt = 0.1
function QueueingSystem:Start()
	self = self :: QueueingSystem
	self.Running = true
	task.spawn(function()
		while self.Running == true do
			task.wait(dt)
			self:ProcessPending()

			--update countdown
			for part, qa in self.QueueingAreas do
				if qa.teleporting.Value == false then
					if qa.currentPlayersNumber == 0 then
						qa.numberValues.countdown.Value = qa.config.countdownFrom
					else
						qa.numberValues.countdown.Value = math.max(qa.numberValues.countdown.Value - dt, 0)
						if qa.numberValues.countdown.Value == 0 then
							qa.teleporting.Value = true
						end
					end
				else
					qa.numberValues.countdown.Value = 0
				end
			end

			for part, qa in self.QueueingAreas do 
				if qa.teleporting.Value == true and qa.teleported == false then
					local players = {}
					for player, _ in pairs(qa.currentPlayersList) do
						table.insert(players, player)
					end
					local newServer = TeleportService:ReserveServer(qa.config.targetPlaceID)
					TeleportService:TeleportToPrivateServer(qa.config.targetPlaceID, newServer, players)
					qa.teleported = true
				end
			end
		end
	end)
end

QueueingSystem.init = function()
	local instance = QueueingSystem.new()
end

return QueueingSystem
