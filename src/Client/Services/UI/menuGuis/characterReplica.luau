local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local peek = Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local sharedValuesTable = require(script.Parent.Parent:WaitForChild("sharedValuesTable"))

--require actual assets

local ComputerStuff = workspace:WaitForChild("ComputerStuff")
local ImportantCStuff = ComputerStuff:WaitForChild("Important") :: Folder
local CharacterCFrame = ImportantCStuff:WaitForChild("CharacterCFrame") :: BasePart

local defaultIdle = "http://www.roblox.com/asset/?id=507766388"


local Player = game.Players.LocalPlayer

type UsedAs<T> = Fusion.UsedAs<T>

local function CharacterReplica( uiValues : sharedValuesTable.sharedValuesTable)
	task.spawn(function()	--we put this in a task spawn because we have to wait for the locaplayers character to not be nil so we dont want to hold up other ui rendering
		local player : Player = game.Players.LocalPlayer
		local character : Model = player.Character or player.CharacterAdded:Wait()
		character.Archivable = true
		local characterClone = character:Clone()
		characterClone.Parent = game.Workspace
		characterClone:PivotTo(CharacterCFrame.CFrame)
		local humanoid : Humanoid = characterClone:WaitForChild("Humanoid") :: Humanoid
		local animator : Animator = humanoid:WaitForChild("Animator") :: Animator
		local animations : {[string] : Animation} = {}	--indexed by anim id

		local animateScript = characterClone:WaitForChild("Animate") :: LocalScript
		animateScript:Destroy()
		--first we inject the default idle
		local defaultIdleAnim = Instance.new("Animation")
		defaultIdleAnim.AnimationId = defaultIdle
		local defualtIdleTrack = animator:LoadAnimation(defaultIdleAnim)
		defualtIdleTrack.Looped = true
		defualtIdleTrack:Play()
		--local observer = uiValues.scope:Observer(uiValues.currentViewingMenu)

end)
  
end

return CharacterReplica