local Frame = require("UserInterface.Frame")

local ViewSelectorFrame = {}

function ViewSelectorFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), ViewSelectorFrame)

	self._VisibleChildIndex = 1

	return self
end

function ViewSelectorFrame:GetChildren(all)
	local children = Frame.GetChildren(self)

	
	if all then
		return children
	else
		return {children[self._VisibleChildIndex]}
	end
end

function ViewSelectorFrame:GetVisibleChildIndex()
	return self._VisibleChildIndex
end

function ViewSelectorFrame:SetVisibleChildIndex(index)
	self._VisibleChildIndex = index
end

return Class.CreateClass(ViewSelectorFrame, "ViewSelectorFrame", Frame)