local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local peek = Fusion.peek
local Children = Fusion.Children
local sharedValuesTable = require(script:WaitForChild("sharedValuesTable"))
local BaseComponents = require(script:WaitForChild("baseComponents"))
local CONFIG = require(script:WaitForChild("CONFIG"))

--ui dependancies
local loaderUI = require(script:WaitForChild("loaderUIV1"))
local menu = require(script:WaitForChild("menu"))
local camera = require(script:WaitForChild("uiCamera"))
local menuGuis = require(script:WaitForChild("menuGuis"))
local characterReplica = require(script:WaitForChild("menuGuis"):WaitForChild("characterReplica"))


local uiValues : sharedValuesTable.sharedValuesTable = sharedValuesTable.new()

local _MainComponent = uiValues.scope:New("ScreenGui") {
	Name = "MainScreenGui",
	IgnoreGuiInset = "True",
	Parent = game.Players.LocalPlayer.PlayerGui,

	[Children] = {

		menu(uiValues, {}),

	}
}

--create the loader ui but it will be parented as a screengui to the player gui

camera(uiValues)
menuGuis(uiValues)
loaderUI(uiValues)
characterReplica(uiValues)

--ui dependancies




local UI = {}



return UI
