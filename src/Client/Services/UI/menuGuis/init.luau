--!strict
--the camera script is part of the ui because it is ONLY modified for ui purposes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local Children = Fusion.Children
local sharedValuesTable = require(script.Parent:WaitForChild("sharedValuesTable"))
local BaseComponents = require(script.Parent.baseComponents)
--local DragAndDrop = require(script:WaitForChild("dragAndDrop"))

--require actual assets

local ComputerStuff = workspace:WaitForChild("ComputerStuff")
local ImportantCStuff = ComputerStuff:WaitForChild("Important") :: Folder
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local inventoryAndShop = require(script:WaitForChild("inventoryAndShop"))




local CONFIG = require(script.Parent:WaitForChild("CONFIG"))

type UsedAs<T> = Fusion.UsedAs<T>

local sideContainerWidthScale = .3
local function menuScreenGui(
    uiValues : sharedValuesTable.sharedValuesTable
)
	local scope = uiValues.scope
	
	local screenGui = scope:New("ScreenGui") {
		DisplayOrder = -1,
		IgnoreGuiInset = true,
		Parent = Player.PlayerGui,
		[Children] = {

		}
	}

	local SectioInTI = TweenInfo.new(.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false)
	local SectionOutTI = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for i = 1 , #CONFIG.sections do
		local sectionName = CONFIG.sections[i]
		if sectionName == "Gadgets" then

			local CGContainer = BaseComponents.CGContainer(
				scope, 
				{
					Position = scope:Tween(
						scope:Computed(function(use)
							return if use(uiValues.currentViewingMenu) == sectionName then UDim2.fromScale(0, 0) else UDim2.new(0,0,1,0)
						end),
					scope:Computed(function(use) 
						return if use(uiValues.currentViewingMenu) == sectionName then SectioInTI else SectionOutTI
					end)),
					Name = sectionName,
					Parent = screenGui,
					Children = {
						scope:New("UIPadding") {
							PaddingLeft = UDim.new(0.025,0),
							PaddingTop = UDim.new(0.1,0),
							PaddingBottom = UDim.new(0.05,0),
							PaddingRight = UDim.new(0.025,0),
						},
						inventoryAndShop(uiValues, {sectionName = sectionName :: string}) :: any--trust it works ;)
						
					} 
				})
			end
		
		
	end


    return screenGui
	
	
end

return menuScreenGui
