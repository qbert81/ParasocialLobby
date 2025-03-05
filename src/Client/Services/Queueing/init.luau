--!strict
local CLS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local RSLib = RS:WaitForChild("Shared"):WaitForChild("Libraries")
local Tags = require(RSLib:WaitForChild("Tags"))
local Types = require(script:WaitForChild("types"))

--dependancyModules
local hrpCollisions = require(script:WaitForChild("hrpCollisions"))
local queueVisuals = require(script:WaitForChild("queueVisuals"))

local QueueAreas : {[BasePart] : Types.QueueArea} = {}


local function RegisterQueuingArea(part : BasePart)
	local newQueueArea : Types.QueueArea = {
		part = part,
		countdown = part:WaitForChild("Countdown") :: NumberValue,
		currentPlayers = part:WaitForChild("CurrentPlayers") :: NumberValue,
		teleporting = part:WaitForChild("Teleporting") :: BoolValue
	}
	QueueAreas[part] = newQueueArea
	queueVisuals.SetupPartForQueue(newQueueArea)
end

for i, v in CLS:GetTagged(Tags.CLS.QueuingArea) do
	if v:IsA("BasePart") then
		RegisterQueuingArea(v)
	end
end

CLS:GetInstanceAddedSignal(Tags.CLS.QueuingArea):Connect(function(instance : Instance)
	if instance:IsA("BasePart") then
		RegisterQueuingArea(instance)
	end
end)


hrpCollisions.Start(QueueAreas)

return {}