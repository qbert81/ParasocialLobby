--!strict
local BoxShaker = require(script:WaitForChild("BoxShaker"))

export type BoxShakeManager = {
	Boxes : { [BasePart]: BoxShaker.BoxShaker },
	ShakeBoxes : (self: BoxShakeManager, strength : number) -> nil,
}

local BoxShakeManager = {}
BoxShakeManager.__index = BoxShakeManager

function BoxShakeManager.new()
	local self = setmetatable({} :: any, BoxShakeManager) :: BoxShakeManager
	self.Boxes = {}
	
	local folder = game.Workspace:WaitForChild("ShakingBoxes")
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			self.Boxes[child] = BoxShaker.new(child)
		end
	end

	folder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			self.Boxes[child] = BoxShaker.new(child)
		end
	end)
	
	return self
end

function BoxShakeManager:ShakeBoxes(strength : number)
	self = self :: BoxShakeManager
	local easeInTime = 0.1
	for _, boxShaker in pairs(self.Boxes) do
		local offset = math.pow(boxShaker.Part.Mass, 0.5) * 0.02 * math.random()
		task.defer(function()
			boxShaker:ShakeBox(strength - offset, (strength - offset)*2.5, .2 + math.random()/8, .8 - offset + math.random()/8)
		end)
		
	end
end

return BoxShakeManager