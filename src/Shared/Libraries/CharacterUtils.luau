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
			print(curElem, v)
			if not curElem then return end
		end
		return curElem:FindFirstChild(name) :: Attachment?
		
	end
	return 
end

return CharacterUtils