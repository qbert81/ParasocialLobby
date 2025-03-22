--!strict
local RSLib = game:GetService("ReplicatedStorage").Shared.Libraries
local Players = game:GetService("Players")
local Tags = require(RSLib.Tags)
local PlaceIds = require(RSLib.PlaceIds)
local QueueConfig = require(script.config)
local TeleportService = game:GetService("TeleportService")
local blinkServer = require(script.Parent.blinkServer)
local CLS = game:GetService("CollectionService")
--When a player joins the countdown starts

local defaultCountdown = 15

export type QueueingArea = { --QueueingAreas are identified by their unique basepart
	part: BasePart,

	--storing current values
	currentPlayersList: { [Player]: boolean? }, --use table.insert or table.remove so we can use # table opperator

	numberValues: {
		currentPlayers: NumberValue,
		maxPlayers: NumberValue,
		countdown: NumberValue,
	},

	teleporting: BoolValue,

	ProcessTouchingHRPS: (QueueingArea, {BasePart}) -> nil, --returns success	| not exposed to client see upper level class
	Teleport : (QueueingArea) -> nil,

}

export type QueueingSystem = {
	Running: boolean,

	QueueingAreas: { [BasePart]: QueueingArea },

	PlayerHRPs : {[Player] : BasePart},

	PlayerCharConnections : {[Player] : {cAdded : RBXScriptConnection, cRemoving : RBXScriptConnection}},
	OverlapParams : OverlapParams,

	Start: (QueueingSystem) -> nil,
}

--QUEUEING AREA -------------------------------------------
local QueueingArea = {}
QueueingArea.__index = QueueingArea

function QueueingArea.new(part: BasePart, maxPlayers : number?)
	local self: QueueingArea = setmetatable({}, QueueingArea) :: any

	self.part = part
	CLS:AddTag(part, Tags.CLS.QueuingArea)
	self.currentPlayersList = {}
	print(maxPlayers)
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

	self.numberValues = {
		countdown = createNumberValue("Countdown"),
		currentPlayers = createNumberValue("CurrentPlayers"),
		maxPlayers = createNumberValue("MaxPlayers"),
	}
	self.numberValues.countdown.Value = defaultCountdown
	self.numberValues.maxPlayers.Value = maxPlayers or 4
	return self
end

function QueueingArea:Teleport() : nil
	self = self :: QueueingArea
	self.teleporting.Value = true
	local function allPlayersGone() : boolean
		for player, _ in self.currentPlayersList do
			if Players:FindFirstChild(player.Name) then
				return true
			end
		end
		return false
	end
	task.spawn(function()
		local convertedPlayers : {Player} = {}
		for i, _ in self.currentPlayersList do
			table.insert(convertedPlayers, i)
		end
		local accessCode = TeleportService:ReserveServer(PlaceIds.InGame)
		TeleportService:TeleportToPrivateServer(PlaceIds.InGame, accessCode, convertedPlayers)
		repeat 
			task.wait(1)
		until allPlayersGone() == true
		task.wait(1.5)
		self.currentPlayersList = {}
		self.numberValues.countdown.Value = QueueConfig.Default.countdownFrom
		self.teleporting.Value = false
	end)
	return
end
function QueueingArea:ProcessTouchingHRPS(hrps : {BasePart}): nil
	self = self :: QueueingArea
	local playersTouchingForThisCheck : {[Player] : boolean} = {}
	for i, hrp in hrps do
		if self.teleporting.Value == true then 
			return 
		end
		if hrp.Parent then
			local player : Player = Players:GetPlayerFromCharacter(hrp.Parent :: any)
			if player then
				playersTouchingForThisCheck[player] = true
				if self.currentPlayersList[player] ~= true then
					self.currentPlayersList[player] = true
					self.numberValues.currentPlayers.Value +=1
				end
				
				if self.numberValues.currentPlayers.Value == self.numberValues.maxPlayers.Value then
					print("Teleporting from here")
					self:Teleport()
				end
			end
		end
	end

	if self.teleporting.Value == true then 
		return 
	end

	for player, _ in self.currentPlayersList do
		if playersTouchingForThisCheck[player] == nil then
			self.currentPlayersList[player] = nil
			self.numberValues.currentPlayers.Value -=1
		end
	end
	return

end

--QUEUEING SYSTEM -------------------------------------------
local QueueingSystem = {}
QueueingSystem.__index = QueueingSystem
function QueueingSystem.new()
	local self: QueueingSystem = setmetatable({}, QueueingSystem) :: any
	self.QueueingAreas = {}

	local function RegisterQueuingArea(part: BasePart)
		self.QueueingAreas[part] = QueueingArea.new(part, part:GetAttribute(Tags.Attributes.QueuePartMaxPlayers))
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

	self.OverlapParams = OverlapParams.new()
	self.OverlapParams.FilterType = Enum.RaycastFilterType.Include
	self.OverlapParams.FilterDescendantsInstances = {}


	self.PlayerCharConnections = {}

	self.PlayerHRPs = {}

	Players.PlayerAdded:Connect(function(player : Player)
		self.PlayerCharConnections[player] = {
			cAdded = player.CharacterAdded:Connect(function(char : Model)
				if char.PrimaryPart then
					self.PlayerHRPs[player] = char.PrimaryPart
				else
					warn("No primary part for char of player", player)
				end
			end),
			cRemoving = player.CharacterRemoving:Connect(function(char : Model)
				self.PlayerHRPs[player] = nil
			end)
		}
	end)

	Players.PlayerRemoving:Connect(function(player : Player)
		local cTable = self.PlayerCharConnections[player]
		if cTable then
			for _, c in cTable :: {RBXScriptConnection} do
				c:Disconnect()
			end
		end
			
	end)
	
	
	self:Start()
	return self
end

local dt = 0.1
function QueueingSystem:Start()
	self = self :: QueueingSystem
	self.Running = true
	task.spawn(function()
		while self.Running == true do
			task.wait(dt)
			local newFilterInstances : {Instance} = {}
			for _, hrp in self.PlayerHRPs do
				table.insert(newFilterInstances, hrp)
			end
			self.OverlapParams.FilterDescendantsInstances = newFilterInstances
			for _, qa in self.QueueingAreas do
				if qa.teleporting.Value == false then
					if qa.numberValues.currentPlayers.Value == 0 then
						qa.numberValues.countdown.Value = defaultCountdown
					else
						qa.numberValues.countdown.Value -= dt
					end
					if qa.numberValues.countdown.Value <= 0 then
						qa.numberValues.countdown.Value = 0
						qa:Teleport()
					else
						qa:ProcessTouchingHRPS(game.Workspace:GetPartsInPart(qa.part, self.OverlapParams))
					end
				end
			end
			
		end
	end)
end

QueueingSystem.init = function()
	local instance = QueueingSystem.new()
end

return QueueingSystem
