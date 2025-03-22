--!strict
--the camera script is part of the ui because it is ONLY modified for ui purposes
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local sharedValuesTable = require(script.Parent:WaitForChild("sharedValuesTable"))
local CameraShaker = require(script:WaitForChild("CameraShaker"))
local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local CharacterPrimaryPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
local BoxShakeManager = require(script:WaitForChild("BoxShakeManager"))

--require actual assets

local ComputerStuff = workspace:WaitForChild("ComputerStuff")
local ImportantCStuff = ComputerStuff:WaitForChild("Important") :: Folder
local InventoryCameraCFrame = ImportantCStuff:WaitForChild("CameraCFrame") :: BasePart
local TruckCameraCFrame = game.Workspace:WaitForChild("TruckCamera") :: BasePart

local TruckCameraFOV = 55
local InventoryCameraFOV = 50
local bumpSoundID = "rbxassetid://9125668055"
local CONFIG = require(script.Parent.CONFIG)

local minTimeBetweenBumps = 1
local maxTimeBeteenBumps = 8


type UsedAs<T> = Fusion.UsedAs<T>


local function Camera(
    uiValues : sharedValuesTable.sharedValuesTable
)

	local boxShakeManager = BoxShakeManager.new()
	local scope = uiValues.scope
	local myCamera = game.Workspace.CurrentCamera
	local currentShakeOffset : CFrame = CFrame.new()
	local nextBumpTime : number = 0

	--CREATE CAMERA SHAKER
	local MyCameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf) 
		currentShakeOffset = cf 
	end)
	MyCameraShaker:Start()
	MyCameraShaker:ShakeSustain(CameraShaker.Presets.RoughDriving)

	
	local function TruckHitsBump()

		nextBumpTime = tick() + math.random(minTimeBetweenBumps, maxTimeBeteenBumps)
		local bumpStrength = .5 + math.random() * 1
		--do the bump
		task.defer(function()
			MyCameraShaker:ShakeOnce(math.pow(bumpStrength,.6)*2.25, 5, .2, .8)
		end)
		
		boxShakeManager:ShakeBoxes(bumpStrength)
		local bumpSound = Instance.new("Sound")
		bumpSound.SoundId = bumpSoundID
		bumpSound.Parent = game.Players.LocalPlayer.PlayerGui
		bumpSound.Volume = .5 + bumpStrength/3
		bumpSound.PlaybackSpeed = math.random(8, 12)/10
		bumpSound:Play()
		game:GetService("Debris"):AddItem(bumpSound,4)
	end
	
	local CameraUpdateOnStep = RunService.RenderStepped:Connect(function(deltaTime : number)
		if scope.peek(uiValues.currentViewingMenu) == "None" then 
			local calcLookAt = CFrame.new(TruckCameraCFrame.CFrame.Position, CharacterPrimaryPart.Position)
			myCamera.CFrame = calcLookAt* currentShakeOffset
			myCamera.FieldOfView = TruckCameraFOV - ((TruckCameraCFrame.Position-CharacterPrimaryPart.Position).Magnitude)/7
			if nextBumpTime < tick() then 
				TruckHitsBump()
			end
		else 
			myCamera.CFrame = InventoryCameraCFrame.CFrame 
		end
	end)

	
	
	local tweenInfo = scope:Computed(function(use) 
		local dt : number = 1
		if use(uiValues.currentViewingMenu) == "None" then 
			dt = 0 
		end
		return TweenInfo.new(dt, Enum.EasingStyle.Quad)
	end)
    return scope:Hydrate(game.Workspace.CurrentCamera) {
        CameraType = Enum.CameraType.Scriptable,
		FieldOfView = scope:Tween(
			scope:Computed(function(use)
					return if use(uiValues.currentViewingMenu) ~= "None" then TruckCameraFOV else InventoryCameraFOV
				end),
			tweenInfo
		),

    }
	
end

return Camera
