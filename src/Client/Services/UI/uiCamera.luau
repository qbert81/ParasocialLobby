--!strict
--the camera script is part of the ui because it is ONLY modified for ui purposes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local sharedValuesTable = require(script.Parent:WaitForChild("sharedValuesTable"))

--require actual assets

local ComputerStuff = workspace:WaitForChild("ComputerStuff")
local ImportantCStuff = ComputerStuff:WaitForChild("Important") :: Folder
local CameraCFrame = ImportantCStuff:WaitForChild("CameraCFrame") :: BasePart


local CONFIG = require(script.Parent.CONFIG)


type UsedAs<T> = Fusion.UsedAs<T>

local function Camera(
    uiValues : sharedValuesTable.sharedValuesTable
)
	local scope = uiValues.scope
	local tweenInfo = scope:Computed(function(use) 
		local dt : number = 1
		if use(uiValues.currentViewingMenu) == "None" then 
			dt = 0 
		end
		return TweenInfo.new(dt, Enum.EasingStyle.Quad)
	end)


    return scope:Hydrate(game.Workspace.CurrentCamera) {
        CameraType = scope:Computed(function(use)
			if use(uiValues.currentViewingMenu) == "None" then 
				return Enum.CameraType.Custom 
			else 
				return Enum.CameraType.Scriptable 
			end
		end),
		CFrame = scope:Computed(function(use)
			if use(uiValues.currentViewingMenu) == "None" then 
				return CFrame.new()
			else 
				return CameraCFrame.CFrame
			end
		end),
		FieldOfView = scope:Tween(
			scope:Computed(function(use)
					return if use(uiValues.currentViewingMenu) ~= "None" then 50 else 70
				end),
			tweenInfo
		),

    }
	
end

return Camera
