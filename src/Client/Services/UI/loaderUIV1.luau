-- loaderUI.luau
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player.PlayerGui
local Fusion = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries"):WaitForChild("Fusion"))
local scoped = Fusion.scoped
local peek = Fusion.peek
local Children, OnEvent, Out = Fusion.Children, Fusion.OnEvent, Fusion.Out
local SharedValuesTable = require(script.Parent.sharedValuesTable)


--Configurables
local cellsPerAxis = 20
local delayInterval = 0.4

local function LoaderUI(uiValues : SharedValuesTable.sharedValuesTable)
	local scope = uiValues.scope

	local function initializeFrames() : {Fusion.Child}
		local children = {}
		for i = 1, cellsPerAxis do
			for j = 1, cellsPerAxis do
				local delay = (i + j) / (cellsPerAxis * 2) * delayInterval
				local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, delay)
				local layoutOrder = i * cellsPerAxis + j
				local lastElemInitScopeCompute : boolean = false
				local newCell = scope:New("Frame") {
					BackgroundTransparency = 1,
					Name = layoutOrder,
					LayoutOrder = layoutOrder,
					[Children] = {
						scope:New("Frame") {
							Rotation = 45,
							BackgroundColor3 = Color3.fromRGB(51, 51, 51),
							Name = "Example UI",
							Size = scope:Tween(
								scope:Computed(function(use)
									if (i+j) - cellsPerAxis * 2 == 0 then 
										if lastElemInitScopeCompute == false then 
											lastElemInitScopeCompute = true
										else
											local temp = peek(uiValues.targetMenu)
											task.delay(.6, function()
												if temp == peek(uiValues.targetMenu) then
													
													uiValues.currentViewingMenu:set(peek(uiValues.targetMenu)) 
													print(peek(uiValues.currentViewingMenu))
												end
											end)
										end
									end
									return if use(uiValues.targetMenu) ~= use(uiValues.currentViewingMenu) then UDim2.new(1.5, 0, 1.5, 0) else UDim2.new(0, 0, 0, 0)
								end),
								TweenInfo
							),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.new(0.5, 0, 0.5, 0),
						},
					}
				}
				table.insert(children, newCell)
			end
		end
		return children
	end
	local vpfSizeRatio = (game.Workspace.CurrentCamera.ViewportSize.X / game.Workspace.CurrentCamera.ViewportSize.Y)
	local screenGui = scope:New("ScreenGui") {
		Name = "LoaderScreen",
		Parent = PlayerGui,
		IgnoreGuiInset = true,
		[Children] = {
			scope:New("CanvasGroup") {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				GroupTransparency = 0,
				Visible = true,
	
				[Children] = {
					scope:New("UIGridLayout") {
						CellSize = UDim2.new(1 / cellsPerAxis , 0, (1 / cellsPerAxis) * vpfSizeRatio , 0),
						CellPadding = UDim2.new(0, 0, 0, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					},
					scope:New("UIAspectRatioConstraint") {
						AspectRatio = vpfSizeRatio,
						AspectType = Enum.AspectType.FitWithinMaxSize,
					},
					initializeFrames()
				}
			}
		}
	
	}

	return screenGui
end

return LoaderUI
