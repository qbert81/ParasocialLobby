--!strict
--CHILDREN SHOULD BE MODULE SCRIPTS SPECIFYING OPTIONAL OVERRIDE FUNCTIONS AND VALUES FOR THE BASEGADGET CLASS 
local CharacterUtils = require(script.Parent.Parent:WaitForChild("CharacterUtils"))
local gadgetDictionary = require(script.Parent)
local GadgetAssetsFolder = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Gadgets")
local gadgetFunctions = {}

export type InventoryBaseGadget ={
	details : gadgetDictionary.GadgetDetails,
	character : Model,
	model : Model,

	--functions
	setupOnCharacter : (InventoryBaseGadget) -> nil,
	deconstruct : (InventoryBaseGadget) -> nil,
}
export type BaseGadget = InventoryBaseGadget& {
	cooldown : NumberValue,	--has to be replicated
	equipped : boolean,

	onEquip : ((BaseGadget) -> nil),
	onUnequip : ((BaseGadget) -> nil),
	onActivateButtonDown : ((BaseGadget) -> nil),
	onActivateButtonUp : ((BaseGadget) -> nil),
}



local function fetchGadgetDetails(gadgetId : number) : gadgetDictionary.GadgetDetails
	return gadgetDictionary[gadgetId] :: gadgetDictionary.GadgetDetails
end
local function fetchGadgetModel(gadgetName : string) : Model?
	local GadgetFolder = GadgetAssetsFolder:WaitForChild(gadgetName) :: Folder?
	if GadgetFolder then
		local GadgetModel = GadgetFolder:WaitForChild(gadgetName) :: Model
		if GadgetModel then
			return GadgetModel:Clone()
		end
		warn("NO MODEL FOUND FOR GADGET " .. gadgetName)
	end
	warn("NO FOLDER FOUND FOR GADGET " .. gadgetName)
	return 
end

local function defaultSetupOnCharacter(character : Model, GadgetModel : Model)
	local AttachmentName = GadgetModel:GetAttribute("ConnectToCharacterAt") :: string or "RightGripAttachment"
	local foundAttachment : Attachment? = CharacterUtils.GetAttachment(character, AttachmentName)
	print(foundAttachment)
	if foundAttachment then
		local primaryPart = GadgetModel.PrimaryPart
		if primaryPart then
			local handle = primaryPart:FindFirstChild("Handle") :: Attachment?
			if handle then
				local RigidConstraint = Instance.new("RigidConstraint")
				RigidConstraint.Parent = GadgetModel
				RigidConstraint.Attachment0 = handle
				RigidConstraint.Attachment1 = foundAttachment
			end
		end
	end
	return nil
end

--CLASSES
local InventoryBaseGadget = {}
InventoryBaseGadget.__index = InventoryBaseGadget
--used for displaying GADGETS on characacter LOCALLY in the INVENTORY
function InventoryBaseGadget.new(character : Model, id : number): InventoryBaseGadget
	local self = setmetatable({} :: any, InventoryBaseGadget)
	self = self :: InventoryBaseGadget
	self.character = character
	self.details = fetchGadgetDetails(id)
	self.model = fetchGadgetModel(self.details.name)
	self:setupOnCharacter()
	return self
end
function InventoryBaseGadget:setupOnCharacter() : nil
	self = self :: InventoryBaseGadget
	local childScript = script:FindFirstChild("name")
	if self.model then
		for _, v in self.model:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
			end
		end
	end
	if childScript and childScript.setupOnCharacter then 
		childScript.setupOnCharacter(self.character, self.model) 
	else
		defaultSetupOnCharacter(self.character, self.model)
	end
	self.model.Parent = game.Workspace
	print(self.model)
	return 
end
function InventoryBaseGadget:deconstruct() : nil
	self = self :: InventoryBaseGadget
	self.model:Destroy()
	self = nil :: any
	return
end



--connect classes to module
gadgetFunctions.InventoryBaseGadget = InventoryBaseGadget

return gadgetFunctions