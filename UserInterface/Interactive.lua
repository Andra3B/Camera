local BASE_CLASS = ...
if not BASE_CLASS then error("Failed to create interative! BASE_CLASS not defined.", 2) end

local Interactive = {}

function Interactive.Create()
	local self = Class.CreateInstance(BASE_CLASS.Create(), Interactive)
	
	self._Active = true

	self._CanFocus = true

	self._FocusedBackgroundColour = Vector4.Create(0.9, 0.9, 0.9, 1)
	self._PressedBackgroundColour = Vector4.Create(1, 1, 1, 1)
	self._HoveringBackgroundColour = Vector4.Create(0.9, 0.9, 0.9, 1)
	self._InactiveOverlayColour = Vector4.Create(0.9, 0.9, 0.9, 0.8)

	return self
end

function Interactive:PostDescendantDraw()
	if not self._Active then
		local absolutePosition = self._AbsolutePosition
		local absoluteSize = self._AbsoluteSize
		local cornerAbsoluteRadius = self._CornerAbsoluteRadius
		
		love.graphics.setColor(self.InactiveOverlayColour:Unpack())
		love.graphics.rectangle(
			"fill",
			absolutePosition.X, absolutePosition.Y,
			absoluteSize.X, absoluteSize.Y,
			cornerAbsoluteRadius, cornerAbsoluteRadius
		)
	end

	BASE_CLASS.PostDescendantDraw(self)
end

function Interactive:GetBackgroundColour()
	local backgroundColour = BASE_CLASS.GetBackgroundColour(self)

	if self._Active then
		if self.Pressed then
			return self.PressedBackgroundColour or backgroundColour
		elseif self.Hovering then
			return self.HoveringBackgroundColour or backgroundColour
		elseif self.Focused then
			return self.FocusedBackgroundColour or backgroundColour
		end
	end
	
	return backgroundColour
end

function Interactive:IsActive()
	return self._Active
end

function Interactive:SetActive(active)
	if active ~= self._Active then
		self._Active = active

		return true, active
	end
end

function Interactive:GetCanFocus()
	return self._CanFocus
end

function Interactive:SetCanFocus(canFocus)
	if canFocus ~= self._CanFocus then
		self._CanFocus = canFocus

		return true, canFocus
	end
end

function Interactive:IsFocused()
	return UserInterface.Focus == self
end

function Interactive:GetFocusedBackgroundColour()
	return self._FocusedBackgroundColour
end

function Interactive:SetFocusedBackgroundColour(colour)
	if colour ~= self._FocusedBackgroundColour then
		self._FocusedBackgroundColour = colour

		return true, colour
	end
end

function Interactive:IsHovering()
	return UserInterface.Hovering == self
end

function Interactive:GetHoveringBackgroundColour()
	return self._HoveringBackgroundColour
end

function Interactive:SetHoveringBackgroundColour(colour)
	if colour ~= self._HoveringBackgroundColour then
		self._HoveringBackgroundColour = colour

		return true, colour
	end
end

function Interactive:IsPressed()
	return UserInterface.Pressed == self
end

function Interactive:GetPressedBackgroundColour()
	return self._PressedBackgroundColour
end

function Interactive:SetPressedBackgroundColour(colour)
	if colour ~= self._PressedBackgroundColour then
		self._PressedBackgroundColour = colour

		return true, colour
	end
end

function Interactive:GetInactiveOverlayColour()
	return self._InactiveOverlayColour
end

function Interactive:SetInactiveOverlayColour(colour)
	if colour ~= self._InactiveOverlayColour then
		self._InactiveOverlayColour = colour

		return true, colour
	end
end

function Interactive:Destroy()
	if not self._Destroyed then
		self._FocusedBackgroundColour = nil
		self._HoveringBackgroundColour = nil
		self._PressedBackgroundColour = nil
		self._InactiveOverlayColour = nil
		
		BASE_CLASS.Destroy(self)
	end
end

return Class.CreateClass(Interactive, "Interactive", BASE_CLASS)