--!strict
local CharacterUtils = {}
export type AttachmentAncestry = {[string] : {string}}

CharacterUtils.AttachmentAncestry  = {
	RightGripAttachment = {"RightHand"},
	LeftGripAttachment = {"LeftHand"},
} :: AttachmentAncestry

CharacterUtils.GetAttachment = function(character : Model, name : string) : Attachment?
	local parents = CharacterUtils.AttachmentAncestry[name]
	local curElem : Instance? = character
	if parents and curElem then
		for _, v in parents do
			curElem = curElem:FindFirstChild(v) :: Instance?
			if not curElem then return end
		end
		curElem = curElem:FindFirstChild(name)
	end
	return 
end

return CharacterUtils