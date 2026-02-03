local Frame = require("UserInterface.Frame")

local ViewSelectorFrame = {}

function ViewSelectorFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), ViewSelectorFrame)

	self._DrawnChildIndex = 1

	return self
end

function ViewSelectorFrame:GetDrawnChildren()
	local children = Frame.GetChildren(self)
	
	return {children[self._DrawnChildIndex]}
end

function ViewSelectorFrame:GetDrawnChildIndex()
	return self._DrawnChildIndex
end

function ViewSelectorFrame:SetDrawnChildIndex(index)
	self._DrawnChildIndex = index
end

return Class.CreateClass(ViewSelectorFrame, "ViewSelectorFrame", Frame)