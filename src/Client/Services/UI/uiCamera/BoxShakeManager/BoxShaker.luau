--!strict
local TS = game:GetService("TweenService")
export type BoxShaker = {
	Part : BasePart,
	OrigionalCFrame : CFrame,
	CurrentShakeTick : number,
	ShakeBox : (BoxShaker, posOffsetMagnitude : number?, rotOffsetMagnitude : number?, easeInTime : number, easeOutTime : number) -> nil
}

local BoxShaker = {}
BoxShaker.__index = BoxShaker

function BoxShaker.new(part: BasePart): BoxShaker
	local self = setmetatable({} :: any, BoxShaker) :: BoxShaker
	self.Part = part
	self.OrigionalCFrame = part.CFrame
	self.CurrentShakeTick = 0
	return self :: BoxShaker
end

function BoxShaker:ShakeBox(posOffsetMagnitude: number?, rotOffsetMagnitude: number?, easeInTime : number, easeOutTime : number): nil
	self = self :: BoxShaker
	-- Implementation will be defined later
	local posOffsetMag : number = posOffsetMagnitude or 0.5
	local rotOffsetMag : number = rotOffsetMagnitude or 0.5
	local thisShakeTime : number = tick()


	self.CurrentShakeTick = thisShakeTime

	local shakeOffsetPosition = Vector3.new(
		0,
		1 ,
		0
	).Unit * posOffsetMag

	local shakeOffsetOrientation = Vector3.new(
		math.random(),
		math.random() ,
		math.random()
	).Unit * rotOffsetMag

	local t1 = thisShakeTime + 0.1
	local cf1 = (self.OrigionalCFrame + shakeOffsetPosition) * CFrame.Angles(math.rad(shakeOffsetOrientation.X), math.rad(shakeOffsetOrientation.Y), math.rad(shakeOffsetOrientation.Z))
	local shakeTweenIn = TS:Create(self.Part, TweenInfo.new(easeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = cf1})
	shakeTweenIn:Play()
	task.wait(easeInTime)
	if self.CurrentShakeTick ~= thisShakeTime then
		return
	end

	local shakeTweenOut = TS:Create(self.Part, TweenInfo.new(easeOutTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = self.OrigionalCFrame})
	shakeTweenOut:Play()
	return
end

return BoxShaker