--!strict
local Debris = game:GetService("Debris")
local Fusion = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries"):WaitForChild("Fusion"))
local peek = Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
type UsedAs<T> = Fusion.UsedAs<T>

--Assets
local RF = game:GetService("ReplicatedFirst")
local UIAssets = RF:WaitForChild("Assets"):WaitForChild("UI")
local Images = UIAssets:WaitForChild("Images")
local MiscImages = Images:WaitForChild("Misc")
local Sounds = UIAssets:WaitForChild("Sounds")
local ButtonHoverSound = Sounds:WaitForChild("Button"):WaitForChild("ButtonHover")
local ButtonClickSound = Sounds:WaitForChild("Button"):WaitForChild("ButtonClick")

local ReverseVignette : ImageLabel = MiscImages:WaitForChild("ReverseVignette")

local BaseComponents = {}
function BaseComponents.ReverseVignette(scope : Fusion.Scope,
    props: {
        Size : UsedAs<UDim2>?,
        ImageColor : UsedAs<Color3>?,
        AnchorPoint : UsedAs<Vector2>?,
        Position : UsedAs<UDim2>?,
    }) 
    : 
    Fusion.Child 
    return scope:New("ImageLabel") {
        Size = props.Size,
        ImageColor3 = props.ImageColor,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        BackgroundTransparency = 1,
        Image = ReverseVignette.Image
    }
end

function BaseComponents.ContainedImageLabel(
    scope: Fusion.Scope,
    props: {
        Name: UsedAs<string>?,
        ContainerFrame: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
            BackgroundColor: UsedAs<Color3>?,
            BackgroundTransparency : UsedAs<number>?
        },
        ImageLabel: {
            ImageId: UsedAs<string>?,
            ImageColor: UsedAs<Color3>?,
            Size: UsedAs<UDim2>?,
        },
        CornerRadius: UsedAs<UDim>?,
        AspectRatio : UsedAs<number>?
    }
): Fusion.Child

    return scope:New "Frame" {
        Name = props.Name,
        Position = props.ContainerFrame.Position,
        AnchorPoint = props.ContainerFrame.AnchorPoint,
        ZIndex = props.ContainerFrame.ZIndex,
        Size = props.ContainerFrame.Size,
        BackgroundColor3 = props.ContainerFrame.BackgroundColor,
        BackgroundTransparency = props.ContainerFrame.BackgroundTransparency,
        [Children] = {
            scope:New("UICorner") {
                CornerRadius = props.CornerRadius
            },
            scope:New("UIAspectRatioConstraint") {
                AspectRatio = props.AspectRatio
            },

            scope:New("ImageLabel") {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = props.ImageLabel.ImageId,
                ImageColor3 = props.ImageLabel.ImageColor,
                Size = props.ImageLabel.Size,
                Position = UDim2.new(0.5,0,0.5,0),
                BackgroundTransparency = 1,
                [Children] = {
                    scope:New("UICorner") {
                        CornerRadius = props.CornerRadius
                    },
                }
                
            },
            
        },
    }
end

function BaseComponents.ImageButton(
    scope: Fusion.Scope,
    props: {
        Name: UsedAs<string>?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?
        },
        CornerRadius : UsedAs<UDim>?,
        ImageId: UsedAs<string>?,
        BackgroundColor : UsedAs<Color3>?,
        AspectRatio : UsedAs<number>?,
        Visible : UsedAs<boolean>?,
        ImageTransparency : UsedAs<number>?,
        BackgroundTransparency : UsedAs<number>?,

        Disabled: UsedAs<boolean>?,
        Interactable : UsedAs<boolean>?,
        Hovered : Fusion.Value<boolean>?,
        OnClick: (() -> ())?,
        Children : {Fusion.Child}?,
        SizeTweenInfo : TweenInfo?
    }
): Fusion.Child
    local hovered = props.Hovered or scope:Value(false)
    local isHeldDown = scope:Value(false)
    local baseSize =  props.Layout.Size :: UDim2
    local _heldDownSize = UDim2.new(baseSize.X.Scale * 0.9, baseSize.X.Offset * 0.9, baseSize.Y.Scale * 0.9, baseSize.Y.Offset * 0.9)
    local _hoveredSize = UDim2.new(baseSize.X.Scale * 1.1, baseSize.X.Offset * 1.1, baseSize.Y.Scale * 1.1, baseSize.Y.Offset * 1.1)
    local SizeTweenInfo = props.SizeTweenInfo or TweenInfo.new(.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    local defaultChildren = {
        scope:New("UICorner") {
            CornerRadius = props.CornerRadius
        },
        scope:New("UIAspectRatioConstraint") {
            AspectRatio = props.AspectRatio or 1
        },
    }
    return scope:New "ImageButton" {
        Name = props.Name,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Image = props.ImageId,
        Visible = props.Visible,
        ImageTransparency = props.ImageTransparency,
        Size = scope:Tween(
            scope:Computed(function(use)
                return if use(isHeldDown) then 
                    _heldDownSize
                elseif use(hovered) then
                    _hoveredSize
                else
                    baseSize
            end),
        SizeTweenInfo),
        BackgroundColor3 = props.BackgroundColor,
        BackgroundTransparency = props.BackgroundTransparency,
        Interactable = props.Interactable,
    
        [Children] = if props.Children then table.move(props.Children, 1, #props.Children, #defaultChildren + 1, defaultChildren) else defaultChildren,

        [OnEvent "Activated"] = function()
            local s = ButtonClickSound:Clone()
                s.Parent = game.Players.LocalPlayer.PlayerGui
                s:Play()
                Debris:AddItem(s, s.TimeLength)
            if props.OnClick ~= nil and not peek(props.Disabled) then
                
                props.OnClick()
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
            local s = ButtonHoverSound:Clone()
                s.Parent = game.Players.LocalPlayer.PlayerGui
                s:Play()
            Debris:AddItem(s, s.TimeLength)
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

--generates a canvas group container to be parented to a screen gui
function BaseComponents.CGContainer(
    scope: Fusion.Scope,
    props: {
        Visible : UsedAs<boolean>?,
        Position : UsedAs<UDim2>?,
        Parent : Instance,
        Name : UsedAs<string>?,
        Children : {Fusion.Child}?
    }
    
): Fusion.Child
local defaultChildren = {}
    return scope:New "CanvasGroup" {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = props.Visible,
        Position = props.Position,
        Parent = props.Parent,
        Name = props.Name,
        [Children] = if props.Children then table.move(props.Children, 1, #props.Children, #defaultChildren + 1, defaultChildren) else defaultChildren,
    }
end


return BaseComponents