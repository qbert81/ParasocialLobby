local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSLib = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Libraries")
local Fusion = require(RSLib:WaitForChild("Fusion"))
local Children = Fusion.Children
local CONFIG = require(script.Parent.Parent.UI:WaitForChild("CONFIG"))
local Types = require(script.Parent.types)


local QueueVisuals = {}

QueueVisuals.SetupPartForQueue = function(qa : Types.QueueArea)
	local thisScope : Fusion.Scope = Fusion:scoped()

	--setup scoped values so we can listen for changes
	local currentPlayers = thisScope:Value(qa.currentPlayers.Value)
	qa.currentPlayers.Changed:Connect(function()
		currentPlayers:set(qa.currentPlayers.Value)
	end)
	local maxPlayers = thisScope:Value(qa.maxPlayers.Value)
	qa.maxPlayers.Changed:Connect(function()
		maxPlayers:set(qa.maxPlayers.Value)
	end)
	local countdown = thisScope:Value(qa.countdown.Value)
	qa.countdown.Changed:Connect(function()
		countdown:set(qa.countdown.Value)
	end)
	local teleporting = thisScope:Value(qa.teleporting.Value)
	qa.teleporting.Changed:Connect(function()
		teleporting:set(qa.teleporting.Value)
	end)
	
	local billboard = thisScope:New("BillboardGui") {
		Size = UDim2.fromScale(10, 10),
		Parent = qa.part:WaitForChild("Billboard"),
		AlwaysOnTop = true,
		[Children] = {
			
			thisScope:New("TextLabel") {	--player count
				Size = UDim2.fromScale(1, .5),
				AnchorPoint = Vector2.new(.5,.5),
				Position = UDim2.fromScale(.5, .25),
				TextColor3 = Color3.new(1.000000, 1.000000, 1.000000),
				TextScaled = true,
				FontFace = CONFIG.font,
				BackgroundTransparency = 1,
				Text = thisScope:Computed(function(use) 
					return tostring(use(currentPlayers)) .. "/" .. tostring(use(maxPlayers))
				end),
				Visible = thisScope:Computed(function(use)  
					return use(teleporting) == false
				end)
			},

			thisScope:New("TextLabel") {	--countdown
				Size = UDim2.fromScale(.75, .3),
				AnchorPoint = Vector2.new(.5,.5),
				Position = UDim2.fromScale(.5, .75),
				TextColor3 = Color3.new(0.721569, 0.721569, 0.721569),
				TextScaled = true,
				FontFace = CONFIG.font,
				BackgroundTransparency = 1,
				Text = thisScope:Computed(function(use) 
					return tostring(math.ceil(use(countdown)))
				end),
				Visible = thisScope:Computed(function(use)  
					return use(teleporting) == false
				end)
			},

			thisScope:New("TextLabel") {	--Teleporting
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(.5,.5),
				Position = UDim2.fromScale(.5, .75),
				TextColor3 = Color3.new(0.874510, 0.874510, 0.874510),
				TextScaled = true,
				FontFace = CONFIG.font,
				BackgroundTransparency = 1,
				Text = "TELEPORTING",
				Visible = thisScope:Computed(function(use)  
					return use(teleporting) == true
				end)
			},

			
		}
	}
	
	return
end

return QueueVisuals
