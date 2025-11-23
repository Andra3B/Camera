local Interactive = loadfile("UserInterface/Interactive.lua")(
	require("UserInterface.Frame")
)

local ScrollFrame = {}

function ScrollFrame.Create()
	local self = Class.CreateInstance(Interactive.Create(), ScrollFrame)

	self._ViewOffset = Vector2.Zero

	return self
end

function ScrollFrame:Destroy()
	if not self._Destroyed then
		self._ViewOffset = nil

		Interactive.Destroy(self)
	end
end

return Class.CreateClass(ScrollFrame, "ScrollFrame", Interactive)