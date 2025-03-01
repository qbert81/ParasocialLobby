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

local RF = game:GetService("ReplicatedFirst")
local UIAssets = RF:WaitForChild("Assets"):WaitForChild("UI")
local UISounds = UIAssets:WaitForChild("Sounds")
local PurchaseButtonSound = UISounds:WaitForChild("Button"):WaitForChild("ButtonPurchase") :: Sound
local Images = UIAssets:WaitForChild("Images"):WaitForChild("Menu")
local BitsImageLabel : ImageLabel = UIAssets:WaitForChild("Images"):WaitForChild("Shop"):WaitForChild("Bit") :: ImageLabel
--local DragAndDrop = require(script:WaitForChild("dragAndDrop"))

export type assets = {
		Assets : Folder,--of models
		Dictionary : {[number] : {
			name : string,
			description : string,
			rarity : number,
			cost : number?,
		}
	} --table of details
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

	
	local ti = TweenInfo.new(3)
	
	local childModel : Fusion.Computed<Model>? = scope:Computed(function(use) 
		if isGadget and cellMenuRenderData.assets.Dictionary[use(itemID)] then
			local derivedScope = scope:deriveScope()
			local modelName = cellMenuRenderData.assets.Dictionary[use(itemID)].name :: string
			local modelFolder = cellMenuRenderData.assets.Assets:WaitForChild(modelName) :: Folder
			local model = modelFolder:WaitForChild(modelName):Clone() :: Model
			local hasCompletedRotation = derivedScope:Value(false)
			model:PivotTo(CFrame.new(Vector3.zero))
			if model.PrimaryPart then
				derivedScope:Hydrate(model.PrimaryPart) {
					Orientation = derivedScope:Tween(derivedScope:Computed(function(_use)
						task.delay(ti.Time, function()
							hasCompletedRotation:set(not Fusion.peek(hasCompletedRotation))
						end)
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

local function ItemCell(uiValues : sharedValuesTable.sharedValuesTable, cellMenuRenderData : cellMenuRenderData, isGadget : boolean) : Fusion.Child?
	local scope = uiValues.scope
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
					Interactable = if cellMenuRenderData.isEquippedCell == false then true else scope:Computed(function(_use)
						return if _use(uiValues.equippingItem) ~= nil then false else true
					end),
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
					Hovered = hovered,
					OnClick = function() 
						if cellMenuRenderData.isEquippedCell then
							uiValues.vieiwngItem:set(Fusion.peek(cellMenuRenderData.equippedTable[cellMenuRenderData.index]))
						else
							uiValues.vieiwngItem:set(Fusion.peek(itemID))
						end
						
					end
				}) 
			end
	end)
end
local function ItemCellHolder(uiValues : sharedValuesTable.sharedValuesTable, 
	cellMenuRenderData : cellMenuRenderData, 
	isGadget : boolean
) : Fusion.Child
	local scope = uiValues.scope
	return scope:New("Frame") {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1
			} :: any,
			BaseComponents.ImageButton(scope, {
				--size is defined in grid layout
				Layout = {
					Size = UDim2.fromScale(1.05, 1.05),
					AnchorPoint = Vector2.new(.5,.5),
					Position = UDim2.fromScale(.5, .5)
				},
				Interactable = if cellMenuRenderData.isEquippedCell == false then false else scope:Computed(function(_use)
					return if _use(uiValues.equippingItem) ~= nil then true else false
				end),
				OnClick = function()	--here we update the equiped item
					uiValues.playerDataObject.equipItem(Fusion.peek(uiValues.equippingItem), cellMenuRenderData.index, Fusion.peek(uiValues.currentViewingMenu))
					uiValues.vieiwngItem:set(nil)
				end,
				BackgroundColor = Color3.new(1,1,1),
				BackgroundTransparency = if cellMenuRenderData.isEquippedCell == false then 1 else scope:Computed(function(_use)
					return if _use(uiValues.equippingItem) ~= nil then 0 else 1
				end),
				ImageTransparency = 1,
				Children = {
					defaultUICorner(scope),
					scope:New("Frame") {
						AnchorPoint = Vector2.new(.5,.5),
						Size = UDim2.fromScale(1/1.05, 1/1.05),
						BackgroundColor3 = CONFIG.primaryColor,
						BackgroundTransparency = .1,
						Position = UDim2.fromScale(.5, .5),
						Visible =  true,
						[Children] = {
							defaultUICorner(scope),
						}
					}
				},
			}),
			ItemCell(uiValues, cellMenuRenderData, isGadget) :: any
		}
	}
end

local function EquippedItemsContainer(uiValues : sharedValuesTable.sharedValuesTable, menuRenderData : menuRenderData, props : {layoutOrder : UsedAs<number>?, sectionName : UsedAs<string>?}) : Fusion.Child
	local scope = uiValues.scope
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
		local newCellHolder = ItemCellHolder(uiValues, cellMenuRenderData, isGadget)
		childItemCells[i] = newCellHolder
	end

	local component = scope:New("CanvasGroup") {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(0.274510, 0.274510, 0.274510),
		Size = UDim2.fromScale(1, .9),
		[Children] = {
			scope:New("UIPadding") {
				PaddingBottom = UDim.new(.04, 0),
				PaddingRight = UDim.new(.00, 0),
				PaddingLeft = UDim.new(.02, 0),
				PaddingTop = UDim.new(.02, 0)
			},
			scope:New("UIGridLayout") {
				CellSize = UDim2.new(.46, 0,.23, 0),
				CellPadding = UDim2.fromScale(.04,.02)
			},
			defaultUICorner(scope),
			childItemCells :: any
		}
	}
	
	return component
end

local function AllItemsContainer(uiValues : sharedValuesTable.sharedValuesTable, menuRenderData : menuRenderData, props : {layoutOrder : UsedAs<number>?, sectionName : UsedAs<string>?}) : Fusion.Child
	local scope = uiValues.scope
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

		itemCellHolders[i] = ItemCellHolder(uiValues, cellMenuRenderData, isGadget)
	end

	local Container = scope:New("CanvasGroup") {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(0.274510, 0.274510, 0.274510),
		Size = UDim2.fromScale(1,.9),
		[Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1
			},
			scope:New("UIPadding") {
				PaddingBottom = UDim.new(.01,0),
				PaddingRight = UDim.new(.0,0),
				PaddingLeft = UDim.new(.02,0),
				PaddingTop = UDim.new(.01*2,0)
			},
			scope:New("UIGridLayout") {
				CellSize = UDim2.new(.32, 0,.32, 0),
				CellPadding = UDim2.fromScale(.01,.01)
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
		PaddingBottom = UDim.new(0,8),
		PaddingRight = UDim.new(0,8),
		PaddingLeft = UDim.new(0,8),
		PaddingTop = UDim.new(0,8),
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
		scope:New("UIListLayout") {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0,5)
		},
		scope:New("UIAspectRatioConstraint")  {
			AspectRatio = .5
		},
	}
	end
	local menuRenderData : menuRenderData = {
		equippedTable = uiValues.playerDataObject.equippedEmotesFS,
		allTable = uiValues.playerDataObject.myEmotesFS,
		assets = AssetDictionary["Emotes" :: sharedValuesTable.menu],
		selectedItemID = nil,
	}
	if props.sectionName == "Gadgets"then
		menuRenderData = {
		equippedTable = uiValues.playerDataObject.equippedGadgetsFS,
		allTable = uiValues.playerDataObject.myGadgetsFS,
		assets = AssetDictionary["Gadgets" :: sharedValuesTable.menu],
		selectedItemID = nil,
	}
	end

	local left = scope:New("CanvasGroup") {
		Size = UDim2.new(.25,0,1,0),
		AnchorPoint = Vector2.new(0,0),
		Position = UDim2.new(0,0,0,0),
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392),
		BackgroundTransparency = 1,
		[Children] = {
			
			
			defaultChildren() :: any,
			HeaderTextLabel(scope, {
				text = 
				("EQUIPPED"),
				layoutOrder = 1,
				size = UDim2.fromScale(1, .07)
			}) :: any,
			EquippedItemsContainer(uiValues, menuRenderData, {sectionName = props.sectionName, layoutOrder = 2}) :: Instance,
		}
	}
	local right = scope:New("CanvasGroup") {
		Size = UDim2.new(sideContainerWidth,0,1,0),
		Position = UDim2.new(1,0,0,0),
		AnchorPoint = Vector2.new(1,0),
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392),
		BackgroundTransparency = 1,
		[Children] = {
			defaultChildren() :: any,
			HeaderTextLabel(scope, {
				text = 
				("ALL " .. (string.upper(props.sectionName :: string))),
				layoutOrder = 1,
				size = UDim2.fromScale(1, .07)
			}) :: any,
			AllItemsContainer(uiValues, menuRenderData, {layoutOrder = 2,sectionName = props.sectionName}) :: any
		}
	}
	local center = scope:New("CanvasGroup") {	-- FOR EQUIP and buy buttons
		Size = UDim2.new(.3,0,.35,0),
		Position = UDim2.new(.5,0,.85,0),
		AnchorPoint = Vector2.new(.5,.5),
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392),
		BackgroundTransparency = .3,
		Visible = scope:Computed(function(use) 
			return if use(uiValues.vieiwngItem) == nil then false else true
		end),
		[Children] = {
			scope:New("UICorner") {
				CornerRadius = CONFIG.defaultCornerRadius
			},
			scope:New("TextLabel") {
				Font = CONFIG.font,
				Size = UDim2.fromScale(.7, .2),
				AnchorPoint = Vector2.new(.5,.5),
				Position = UDim2.fromScale(.5, .1),
				TextScaled = true,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Text = scope:Computed(function(use)
					if use(uiValues.vieiwngItem) and menuRenderData.assets.Dictionary[use(uiValues.vieiwngItem) ::number] then
						return menuRenderData.assets.Dictionary[use(uiValues.vieiwngItem) :: number].name
					else
						return ""
					end
				end)
			},
			scope:New("TextLabel") {
				Font = CONFIG.font,
				Size = UDim2.fromScale(.9, .3),
				AnchorPoint = Vector2.new(.5,.5),
				Position = UDim2.fromScale(.5, .4),
				TextSize = 20,
				TextWrapped = true,
				BackgroundTransparency = 1,
				TextColor3 = Color3.new(1,1,1),
				Text = scope:Computed(function(use)
					if use(uiValues.vieiwngItem) and menuRenderData.assets.Dictionary[use(uiValues.vieiwngItem) ::number] then
						return menuRenderData.assets.Dictionary[use(uiValues.vieiwngItem) :: number].description
					else
						return ""
					end
				end)
			},
			BaseComponents.ImageButton(scope, {
				AspectRatio = 3,
				Layout = {
					Size = UDim2.fromScale(.6, .35),
					AnchorPoint = Vector2.new(.5,.5),
					Position = UDim2.fromScale(.5, .75),
				},
				OnClick = function() 
					if Fusion.peek(uiValues.vieiwngItem) and Fusion.peek(menuRenderData.allTable[Fusion.peek(uiValues.vieiwngItem) :: number]) == true then
						uiValues.equippingItem:set(Fusion.peek(uiValues.vieiwngItem))
					else
						if Fusion.peek(uiValues.vieiwngItem) ~= nil then
							local itemDict = menuRenderData.assets.Dictionary[Fusion.peek(uiValues.vieiwngItem) :: number ]
							local bits = uiValues.playerDataObject.playerData.Bits
							if bits and itemDict.cost and bits < itemDict.cost then
								uiValues.targetMenu:set("Shop")
								uiValues.currentViewingMenu:set("Shop")
							else
								local bps = PurchaseButtonSound:Clone()
								bps.Parent = game.Players.LocalPlayer.PlayerGui
								bps:Play()
								game:GetService("Debris"):AddItem(bps, bps.TimeLength)
								uiValues.playerDataObject.purchaseInventoryItem(Fusion.peek(uiValues.vieiwngItem), Fusion.peek(uiValues.currentViewingMenu))
							end
						end
						
					end
				end,
				Children = {
					scope:New("UICorner") {
						CornerRadius = CONFIG.defaultCornerRadius,
					},
					scope:New("UIGradient") {
						Rotation = -90,
						Color = scope:Computed(function(use) 
							return if use(uiValues.vieiwngItem) and use(menuRenderData.allTable[use(uiValues.vieiwngItem) :: number]) ~= true then 
								ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 161, 74)),
									ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 152, 34)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 161, 74))
								})
							else
								ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(193, 193, 253)),
									ColorSequenceKeypoint.new(0.5, Color3.fromRGB(171, 171, 255)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(193, 193, 252))
								})
						end)
					},
					scope:New("UIPadding") {
						PaddingBottom = UDim.new(.02,0),
						PaddingTop = UDim.new(.02,0),
						PaddingRight = UDim.new(.05,0),
						PaddingLeft = UDim.new(.05,0),
					},
					scope:New("TextLabel") {
						Size = UDim2.fromScale(.6, .6),
						AnchorPoint = Vector2.new(.5,.5),
						Position = scope:Computed(function(use)
							if use(uiValues.vieiwngItem) and use(menuRenderData.allTable[use(uiValues.vieiwngItem) :: number]) ~= true then
								return UDim2.fromScale(.65, .5)
							else
								return UDim2.fromScale(.5, .5)
							end
						end),
						TextScaled = true,
						BackgroundTransparency = 1,
						TextColor3 = Color3.new(1,1,1),
						Font = Enum.Font.ArialBold,
						TextXAlignment = scope:Computed(function(use)
							if use(uiValues.vieiwngItem) and use(menuRenderData.allTable[use(uiValues.vieiwngItem) :: number]) ~= true then
								return Enum.TextXAlignment.Center
							else
								return Enum.TextXAlignment.Center
							end
						end),
						Text = scope:Computed(function(use)
							if use(uiValues.vieiwngItem) and use(menuRenderData.allTable[use(uiValues.vieiwngItem) :: number]) ~= true then
								return tostring(menuRenderData.assets.Dictionary[use(uiValues.vieiwngItem) :: number].cost)
							else
								return "Use"
							end
						end)
					},

					--children for equip
					scope:New("ImageLabel") {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(.3,1),
						AnchorPoint = Vector2.new(.5,.5),
						Position = UDim2.fromScale(.15,.5),
						Image = BitsImageLabel.Image,
						Visible = scope:Computed(function(use) 
							return use(uiValues.vieiwngItem) and use(menuRenderData.allTable[use(uiValues.vieiwngItem) :: number]) ~= true
						end),
						[Children] = {
							scope:New("UIAspectRatioConstraint") {
								AspectRatio = 1,
							}
						}
					}
				}
				}
			) :: any
		}
	}
	return {left, right, center}
end


return Container