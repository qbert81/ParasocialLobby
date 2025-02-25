local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local peek = Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local sharedValuesTable = require(script.Parent:WaitForChild("sharedValuesTable"))
local baseComponents = require(script.Parent.baseComponents)

--require actual assets
local RF = game:GetService("ReplicatedFirst")
local UIAssets = RF:WaitForChild("Assets"):WaitForChild("UI")
local Images = UIAssets:WaitForChild("Images"):WaitForChild("Menu")
local Sounds = UIAssets:WaitForChild("Sounds")
local ButtonHoverSound = Sounds:WaitForChild("Button"):WaitForChild("ButtonHover")
local ButtonClickSound = Sounds:WaitForChild("Button"):WaitForChild("ButtonClick")

local Player = game.Players.LocalPlayer

local CONFIG = require(script.Parent:WaitForChild("CONFIG"))
local sections : {string} = CONFIG.sections
local sectionColors = CONFIG.sectionColors

type UsedAs<T> = Fusion.UsedAs<T>

local function MenuButton(
    uiValues : sharedValuesTable.sharedValuesTable,
    props: {
        Name: UsedAs<string>,
        ImageId : UsedAs<string>,
    }
): Fusion.Child?
	local scope = uiValues.scope
    --local state variables
    local hovered = scope:Value(false)
    local isHeldDown = scope:Value(false)
    local TWEEN_INFO = TweenInfo.new(.3,Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false)

    local OnClick = function()
        if props.Name ~= "None" and peek(uiValues.currentViewingMenu) ~= "None" then
            uiValues.currentViewingMenu:set(props.Name :: sharedValuesTable.menu)
        end
        uiValues.targetMenu:set(props.Name :: sharedValuesTable.menu)
    end

    return scope:New "ImageButton" {
        Name = props.Name,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(.2, 1),
        BackgroundColor3 = CONFIG.primaryColor,
        
		AnchorPoint = Vector2.new(.5,0),
		Position = UDim2.fromScale(.5, 0),

		
		[Children] = {
            baseComponents.ReverseVignette(scope, {
                Size = UDim2.fromScale(1.7, 1.7),
                AnchorPoint = Vector2.new(.5,.5),
                ImageColor = sectionColors[props.Name :: sharedValuesTable.menu],
                Position = UDim2.fromScale(.5, .5)
            }),
			scope:New("UICorner") {
                CornerRadius = UDim.new(.3,0)
            },
            scope:New("UIAspectRatioConstraint") {
                AspectRatio =  scope:Tween(
                    scope:Computed(function(use)
                    return if use(hovered) then .74 else 1
                end),
                TWEEN_INFO
            )}, 
            baseComponents.ContainedImageLabel(scope, {
                ContainerFrame= {
                    Position= UDim2.new(.5,0,1,0),
                    AnchorPoint = Vector2.new(.5,1),
                    Size = UDim2.new(1,0,1,0),
                    BackgroundColor = sectionColors[props.Name :: sharedValuesTable.menu],
                },
                ImageLabel= {
                    CornerRadius = UDim.new(.3,0),
                    ImageId= props.ImageId,
                    Size= UDim2.new(.7,0,.7,0),
                },
                CornerRadius = UDim.new(.3,0),
                AspectRatio = 1,
            }),
            scope:New("UIPadding") {
                PaddingBottom = UDim.new(.1,0),
                PaddingLeft = UDim.new(.1,0),
                PaddingRight = UDim.new(.1,0),
                PaddingTop = UDim.new(.1,0)
            },

		},
        [OnEvent "Activated"] = function()
            local s = ButtonClickSound:Clone() :: Sound
            s.Parent = Player.PlayerGui
            s:Play()
            game:GetService("Debris"):AddItem(s, s.TimeLength)
            if OnClick ~= nil then
                OnClick()
            end
        end,

        [OnEvent "MouseButton1Down"] = function()
            isHeldDown:set(true)
        end,
        [OnEvent "MouseButton1Up"] = function()
            isHeldDown:set(false)
        end,

        [OnEvent "MouseEnter"] = function()
            -- Roblox calls this event even if the button is being covered by
            -- other UI. For simplicity, this does not account for that.
            local s = ButtonHoverSound:Clone() :: Sound
            s.Parent = Player.PlayerGui
            s:Play()
            game:GetService("Debris"):AddItem(s, s.TimeLength)
            hovered:set(true)
        end,
        [OnEvent "MouseLeave"] = function()
            -- If the button is being held down, but the cursor moves off the
            -- button, then we won't receive the mouse up event. To make sure
            -- the button doesn't get stuck held down, we'll release it if the
            -- cursor leaves the button.
            isHeldDown:set(false)
            hovered:set(false)
        end,
    }
	
end
local function Menu(
    uiValues : sharedValuesTable.sharedValuesTable,
    props: {
        Name: UsedAs<string>?,
    }
): Fusion.Child
	local scope = uiValues.scope

    return scope:New "CanvasGroup" {
        Name = props.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.4,0.2),
		AnchorPoint = Vector2.new(.5,0),
		Position = UDim2.fromScale(.5, 0),

		Visible =  scope:Computed(function(use)
                return if use(uiValues.currentViewingMenu) == "None" then true else true
        end),
		[Children] = {
			scope:New "UIListLayout" {
                VerticalAlignment = "Top",
                HorizontalAlignment = "Center",
                FillDirection = "Horizontal",
                HorizontalFlex = "SpaceEvenly",
            },
            scope:ForValues(sections, function(_use, _scope, value : string)
                if value ~= "None" then 
                local ImageLabel = Images:WaitForChild(value) :: ImageLabel
                if ImageLabel then
                    return MenuButton(uiValues, {Name = value, ImageId = ImageLabel.Image})
                end
            end
                return
            end),
            scope:New("UIPadding") {
                PaddingBottom = UDim.new(.1,0),
                PaddingTop = UDim.new(.1,0)
            },
            scope:New("UIAspectRatioConstraint") {
                AspectRatio =  2.5
            }, 
		}
    }
	
end

return Menu