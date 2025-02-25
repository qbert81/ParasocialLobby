export type Rarity = {
	id : number,
	name : string,
	color : Color3,
}
type rarities ={
	colors : {[number]: Rarity},
	rarityColorSequences : {[number]: ColorSequence}
}
return {
	colors = {
		[1] = {
			id = 1,
			name = "Common",
			color = Color3.fromRGB(153, 153, 153),
		},
		[2] = {
			id = 2,
			name = "Uncommon",
			color = Color3.fromRGB(144, 238, 144),
		},
		[3] = {
			id = 3,
			name = "Rare",
			color = Color3.fromRGB(105, 105, 252),
		},
		[4] = {
			id = 4,
			name = "Epic",
			color = Color3.fromRGB(128, 0, 128),
		},
		[5] = {
			id = 5,
			name = "Legendary",
			color = Color3.fromRGB(255, 215, 0),
		}
	},
	rarityColorSequences = {
		[1] = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 102, 102)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(153, 153, 153)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 204, 204)),
		}),
		[2] = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 205, 102)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(144, 238, 144)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(186, 255, 186)),
		}),
		[3] = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 54, 161)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(161, 161, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 255)),
		}),
		[4] = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 0, 76)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(128, 0, 128)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(179, 0, 179)),
		}),
		[5] = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(204, 172, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 102)),
		})
	}
} :: rarities
