--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local BaseComponents = require(script.Parent.Parent:WaitForChild("baseComponents"))
--fusion
local Fusion = require(RSLib:WaitForChild("Fusion"))
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

local sharedValuesTable = require(script.Parent.Parent:WaitForChild("sharedValuesTable"))

local CONFIG = require(script.Parent.Parent:WaitForChild("CONFIG"))
local RarityDetails = require(RSLib:WaitForChild("Rarities"))
--local DragAndDrop = require(script:WaitForChild("dragAndDrop"))

export type assets = {
		Assets : Folder,--of models
		Dictionary : {[number] : any} --table of details
}

local AssetDictionary : 
{
	[sharedValuesTable.menu] : assets	
} = {
	Gadgets = {
		Assets = Assets:WaitForChild("Gadgets") :: Folder,
		Dictionary = require(RSLib:WaitForChild("GadgetsDictionary"))
	},
	Emotes = nil,

}

export type menuRenderData = {
	assets : assets,
	equippedTable : {[number] : Fusion.Value<number>},
	allTable : {[number] : Fusion.Value<boolean>},
	selectedItemID : number?,
}

type cmdValueType = number | boolean
export type cellMenuRenderData = {
	index : number,
	isEquippedCell : boolean	--if value type is a boolean then its for all items if number its id of item we have to fetch from pData/dict :)
} & menuRenderData


local function defaultUICorner(scope : Fusion.Scope) : Instance
	return scope:New("UICorner") {
		CornerRadius = UDim.new(CONFIG.defaultCornerRadius.Scale, CONFIG.defaultCornerRadius.Offset)
	}
end

local function itemVPF(scope : Fusion.Scope, cellMenuRenderData : cellMenuRenderData, isGadget: boolean, itemID : Fusion.Computed<number>) : Instance

	local hasCompletedRotation = scope:Value(false)
	local ti = TweenInfo.new(3)

	local childModel : Fusion.Computed<Model>? = scope:Computed(function(use) 
		if isGadget then
			local modelName = cellMenuRenderData.assets.Dictionary[use(itemID)].name :: string
			local modelFolder = cellMenuRenderData.assets.Assets:WaitForChild(modelName) :: Folder
			local model = modelFolder:WaitForChild(modelName):Clone() :: Model
			model:PivotTo(CFrame.new(Vector3.zero))
			if model.PrimaryPart then
				scope:Hydrate(model.PrimaryPart) {
					Orientation = scope:Tween(scope:Computed(function(_use)
						task.delay(ti.Time, function()
							hasCompletedRotation:set(not Fusion.peek(hasCompletedRotation))
						end)
						print(Fusion.peek(hasCompletedRotation))
						if _use(hasCompletedRotation) then 
							return Vector3.new(0,-90,0) 
							
						else
							return Vector3.new(0,90,0)
						end
					end),
					ti
				)
				}
			end

			
			return model :: Model
		else
			return Instance.new("Model")
		end
	end)
	local realModel = Fusion.peek(childModel) :: Model
	local YStudsOffsetVPF = realModel:GetAttribute("YStudsOffsetVPF") :: number or 0
	local ZStudsOffsetVPF = realModel:GetAttribute("ZStudsOffsetVPF") :: number or 0
	local viewportFrame = scope:New("ViewportFrame") {
		ImageColor3 = scope:Computed(function(_use)
			return if _use(cellMenuRenderData.allTable[_use(itemID)])  ~= true then Color3.new(0,0,0) else Color3.new(1,1,1)
		end),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CurrentCamera = scope:New("Camera") {
			CFrame = CFrame.lookAt(Vector3.new(0,YStudsOffsetVPF,1.75 + ZStudsOffsetVPF), Vector3.new(0,YStudsOffsetVPF,0)),
			Focus = CFrame.new(Vector3.zero)
		},
		[Children] = {
				[Children] = {
					scope:New("WorldModel") {
						[Children] = childModel
					}
				}
		}		
	} :: ViewportFrame

	return scope:New("Frame") {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[Children] = {
			viewportFrame
		}
	}
end

local function ItemCell(scope : Fusion.Scope, cellMenuRenderData : cellMenuRenderData, isGadget : boolean) : Fusion.Child?
	local hovered = scope:Value(false)
	local tableToTrack = if cellMenuRenderData.isEquippedCell then cellMenuRenderData.equippedTable else cellMenuRenderData.allTable
	local itemID = scope:Computed(function(use)
		return if(cellMenuRenderData.isEquippedCell) then use(tableToTrack[cellMenuRenderData.index]) else cellMenuRenderData.index
	end)
	return scope:Computed(function(use) : Fusion.Child?
		if cellMenuRenderData.isEquippedCell == true and use(cellMenuRenderData.equippedTable[cellMenuRenderData.index]) == nil then 
				return nil 
			else 
				return BaseComponents.ImageButton(scope, {
					Name = tostring(cellMenuRenderData.index),
					Layout = {
						Size = UDim2.fromScale(.9, .9),
						AnchorPoint = Vector2.new(.5,.5),
						Position = UDim2.fromScale(.5, .5)
					},
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					BackgroundColor = CONFIG.primaryColor,
					CornerRadius = CONFIG.defaultCornerRadius,
					SizeTweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					Children = {
						scope:New("CanvasGroup") {
							Size = UDim2.fromScale(1.05, 1.05),
							AnchorPoint = Vector2.new(.5,.5),
							Position = UDim2.fromScale(.5,.5),
							BackgroundColor3 = Color3.new(1,1,1),
							BackgroundTransparency =  scope:Tween(
								scope:Computed(function(_use)
									return if _use(hovered) then 
										0
									else 
									1
								end),
								TweenInfo.new(.2,Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
							),
							[Children] = {
								defaultUICorner(scope),
								scope:New("Frame") {
									Size = UDim2.fromScale(.95, .95),
									AnchorPoint = Vector2.new(.5,.5),
									Position = UDim2.fromScale(.5,.5),
									BackgroundColor3 = scope:Tween(
										scope:Computed(function(_use)
											return if _use(hovered) then 
												CONFIG.lighterColor
											else 
												CONFIG.primaryColor
										end),
										TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
									BackgroundTransparency = 0,
									
									[Children] = {
										defaultUICorner(scope),
										scope:New("Frame") {
											Size = UDim2.fromScale(.95, .95),
											AnchorPoint = Vector2.new(.5,.5),
											Position = UDim2.fromScale(.5, .5),
											[Children] = {
												scope:New("UIGradient") {
													Color = RarityDetails.rarityColorSequences[cellMenuRenderData.assets.Dictionary[Fusion.peek(itemID)].rarity],
													Rotation = -45
												},
												defaultUICorner(scope),
												itemVPF(scope, cellMenuRenderData, isGadget, itemID)
											}
										}
									}
								}
							}
						}
					},
					Hovered = hovered
				}) 
			end
	end)
end
local function ItemCellHolder(scope : Fusion.Scope, 
	cellMenuRenderData : cellMenuRenderData, 
	isGadget : boolean
) : Fusion.Child
	
	return scope:New("Frame") {
		--size is defined in grid layout
		BackgroundColor3 = CONFIG.primaryColor,
		BackgroundTransparency = .1,
		[Children] = {
			defaultUICorner(scope),
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1
			},
			ItemCell(scope, cellMenuRenderData, isGadget) :: Instance
		},
	}
end

local function EquippedItemsContainer(scope : Fusion.Scope, menuRenderData : menuRenderData, props : {layoutOrder : UsedAs<number>?, sectionName : UsedAs<string>?}) : Fusion.Child
	local isGadget = props.sectionName == "Gadgets"
	local childItemCells : {Fusion.Child} = {}
	for i=1, 8 do
		local cellMenuRenderData = {
			assets = menuRenderData.assets,
			equippedTable = menuRenderData.equippedTable,
			allTable = menuRenderData.allTable,
			selectedItemID = menuRenderData.selectedItemID,
			index = i,
			isEquippedCell = true
		}
		local newCellHolder = ItemCellHolder(scope, cellMenuRenderData, isGadget)
		childItemCells[i] = newCellHolder
	end

	local component =  scope:New("CanvasGroup") {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(0.274510, 0.274510, 0.274510),
		Size = UDim2.fromScale(1, 0.9),
		[Children] = {
			scope:New("UIPadding") {
				PaddingBottom = UDim.new(.04, 0),
				PaddingRight = UDim.new(.00, 0),
				PaddingLeft = UDim.new(.02, 0),
				PaddingTop = UDim.new(.04*2, 0)
			},
			scope:New("UIGridLayout") {
				CellSize = UDim2.new(.23, 0,.46, 0),
				CellPadding = UDim2.fromScale(.02,.04)
			},
			defaultUICorner(scope),
			childItemCells :: any
		}
	}
	
	return component
end

local function AllItemsContainer(scope : Fusion.Scope, menuRenderData : menuRenderData, props : {layoutOrder : UsedAs<number>?, sectionName : UsedAs<string>?}) : Fusion.Child
	local isGadget = props.sectionName == "Gadgets"
	local itemCellHolders : {Fusion.Child} = {}
	for i, _v in menuRenderData.assets.Dictionary do
		local cellMenuRenderData = {
			assets = menuRenderData.assets,
			equippedTable = menuRenderData.equippedTable,
			allTable = menuRenderData.allTable,
			selectedItemID = menuRenderData.selectedItemID,
			index = i,
			isEquippedCell = false
		}

		itemCellHolders[i] = ItemCellHolder(scope, cellMenuRenderData, isGadget)
	end

	local Container = scope:New("CanvasGroup") {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(0.274510, 0.274510, 0.274510),
		Size = UDim2.new(1,0,.8,0),
		[Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1
			},
			scope:New("UIPadding") {
				PaddingBottom = UDim.new(.02,0),
				PaddingRight = UDim.new(.0,0),
				PaddingLeft = UDim.new(.02,0),
				PaddingTop = UDim.new(.02*2,0)
			},
			scope:New("UIGridLayout") {
				CellSize = UDim2.new(.23, 0,.23, 0),
				CellPadding = UDim2.fromScale(.02,.02)
			},
			defaultUICorner(scope),
			itemCellHolders :: any
		}
	}
	
	return Container
end
--require actual assets
local function HeaderTextLabel(scope : Fusion.Scope, props : {
	text : UsedAs<string>?,
	size : UsedAs<UDim2>?,
	layoutOrder : UsedAs<number>?
}) : Fusion.Child
	return scope:New("TextLabel") {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1,1,1),
		TextScaled = true,
		Font = CONFIG.font,
		Text = props.text,
		Size = props.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
	}
end

local function UIPaddingForSides(uiValues : sharedValuesTable.sharedValuesTable) : Fusion.Child
	return uiValues.scope:New("UIPadding") {
		PaddingBottom = UDim.new(.05,0),
		PaddingRight = UDim.new(.05,0),
		PaddingLeft = UDim.new(.05,0),
		PaddingTop = UDim.new(.05,0),
	}
end
local sideContainerWidth = .35
local function Container(uiValues : sharedValuesTable.sharedValuesTable, props : {
	sectionName : UsedAs<string>
}) : {Fusion.Child}

	local scope = uiValues.scope
	local function defaultChildren() : {Fusion.Child}
		return {
		scope:New("UICorner") {
			CornerRadius = CONFIG.defaultCornerRadius
		},
		UIPaddingForSides(uiValues),
	}
	end
	local menuRenderData : menuRenderData = {
		equippedTable = uiValues.equippedEmotesFS,
		allTable = uiValues.myEmotesFS,
		assets = AssetDictionary["Emotes" :: sharedValuesTable.menu],
		selectedItemID = nil,
	}
	if props.sectionName == "Gadgets"then
		menuRenderData = {
		equippedTable = uiValues.equippedGadgetsFS,
		allTable = uiValues.myGadgetsFS,
		assets = AssetDictionary["Gadgets" :: sharedValuesTable.menu],
		selectedItemID = nil,
	}
	end

	local left = scope:New("CanvasGroup") {
		Size = UDim2.new(sideContainerWidth,0,.5,0),
		AnchorPoint = Vector2.new(0,.5),
		Position = UDim2.new(0,0,.5,0),
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392),
		BackgroundTransparency = 1,
		[Children] = {
			
			scope:New("UIAspectRatioConstraint")  {
				AspectRatio = 1.5
			},
			scope:New("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(.02,0)
			},
			defaultChildren() :: any,
			HeaderTextLabel(scope, {
				text = 
				("EQUIPPED"),
				layoutOrder = 1,
				size = UDim2.fromScale(1, .1)
			}) :: any,
			EquippedItemsContainer(uiValues.scope, menuRenderData, {sectionName = props.sectionName, layoutOrder = 2}) :: Instance,
		}
	}
	local right = scope:New("CanvasGroup") {
		Size = UDim2.new(sideContainerWidth,0,1,0),
		Position = UDim2.new(1,0,.5,0),
		AnchorPoint = Vector2.new(1,.5),
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392),
		BackgroundTransparency = .4,
		[Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = .7
			},
			defaultChildren() :: any,
			scope:New("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(.02,0)
			},
			HeaderTextLabel(scope, {
				text = 
				("ALL " .. (string.upper(props.sectionName :: string))),
				layoutOrder = 1,
				size = UDim2.fromScale(1, 0.1/1.5*.7)
			}) :: any,
			AllItemsContainer(scope, menuRenderData, {layoutOrder = 2,sectionName = props.sectionName}) :: any
		}
	}
	return {left, right}
end


return Container