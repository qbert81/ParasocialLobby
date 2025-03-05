--!strict
local Player = game:GetService("Players").LocalPlayer
local Types = require(script.Parent:WaitForChild("types"))
local RunService = game:GetService("RunService")
local blinkClient = require(script.Parent.Parent:WaitForChild("blinkClient"))

local inQueue: BasePart? = nil
local isRunning: boolean = false
local hrpCollisions = {}

hrpCollisions.Start = function(queueAreas: { [BasePart]: Types.QueueArea })
	isRunning = true
	local connection: RBXScriptConnection
	task.spawn(function()
		while isRunning do

			task.wait(.05)
			local pCharacter: Model? = Player.Character
			if pCharacter and pCharacter.PrimaryPart then
				local overlapParams = OverlapParams.new()
				local fdi = {}
				for i, _ in queueAreas do
					table.insert(fdi, i)
				end
				overlapParams.FilterType = Enum.RaycastFilterType.Include
				overlapParams.FilterDescendantsInstances = fdi :: any
				local result = game.Workspace:GetPartsInPart(pCharacter.PrimaryPart, overlapParams)
				if #result > 0 then
					if inQueue == nil then
						local partHit : BasePart = result[1]
						inQueue = partHit
						blinkClient.Enqueue.Fire(partHit)
					end
				else
					if inQueue ~= nil then
						
						blinkClient.Dequeue.Fire(inQueue)
						inQueue = nil
					end
				end
			end
		end
	end)
	
end

return hrpCollisions
