--!strict
local CONFIG = {}
CONFIG.sections = {
    "Gadgets",
    "Emotes",
    "None",
    "Shop"
}

CONFIG.sectionColors = {
    ["Shop"] = Color3.fromRGB(255, 0, 0), -- Bright Red
    ["Gadgets"] = Color3.fromRGB(255, 0, 255), -- Bright Magenta
    ["Emotes"] = Color3.fromRGB(0, 255, 0), -- Bright Green
    ["None"] = Color3.fromRGB(255, 255, 255), -- Teal
}

CONFIG.defaultCornerRadius = UDim.new(0,15)
CONFIG.font = Enum.Font.Arial
CONFIG.primaryColor = Color3.new(0.113725, 0.113725, 0.113725)
CONFIG.lighterColor = Color3.new(0.352941, 0.352941, 0.352941)
return CONFIG