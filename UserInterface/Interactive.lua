local BASE_CLASS = ...
if not BASE_CLASS then error("Failed to create interative widget! BASE_CLASS not defined.", 2) end

local Interactive = {}

function Interactive.Create()
	local self = Class.CreateInstance(BASE_CLASS.Create(), Interactive)
	
	self._Active = true
	self._AbsoluteActive = true
	
	self._Focused = false
	self._CanFocus = true

	self._PressedBackgroundColour = nil
	self._PressedColourMultiplier = 2

	self._InactiveOverlayColour = Vector4.Create(0.8, 0.8, 0.8, 0.75)
	
	self._FocusedBackgroundColour = nil
	self._FocusedColourMultiplier = 1.5
	
	self._HoveringBackgroundColour = nil
	self._HoveringColourMultiplier = 1.5

	return self
end

function Interactive:Refresh()
	BASE_CLASS.Refresh(self)

	local interactiveAncestor = self:GetAncestorWithType("Interactive")

	if interactiveAncestor then
		self._AbsoluteActive = interactiveAncestor._AbsoluteActive and self._Active
	else
		self._AbsoluteActive = self._Active
	end
end

function Interactive:PostDraw()
	if not self._AbsoluteActive then
		local absolutePosition = self._AbsolutePosition
		local absoluteSize = self._AbsoluteSize
		local cornerRadius = self:GetCornerRadius()

		love.graphics.setColor(self:GetInactiveOverlayColour():Unpack())
		love.graphics.rectangle(
			"fill",
			absolutePosition.X, absolutePosition.Y,
			absoluteSize.X, absoluteSize.Y,
			cornerRadius, cornerRadius
		)
	end
end

function Interactive:GetBackgroundColour()
	local backgroundColour = BASE_CLASS.GetBackgroundColour(self)

	if self._AbsoluteActive then
		if self:IsPressed() then
			return
				self:GetPressedBackgroundColour() or
				backgroundColour * self:GetPressedColourMultiplier()
		elseif self:IsHovering() then
			return
				self:GetHoveringBackgroundColour() or
				backgroundColour * self:GetHoveringColourMultiplier()
		elseif self:IsFocused() then
			return
				self:GetFocusedBackgroundColour() or
				backgroundColour * self:GetFocusedColourMultiplier()
		end
	end
	
	return backgroundColour
end

function Interactive:IsActive()
	return self._Active
end

function Interactive:GetAbsoluteActive()
	return self._AbsoluteActive
end

function Interactive:GetInactiveOverlayColour()
	return self._InactiveOverlayColour
end

function Interactive:SetActive(active)
	self._Active = active

	if self:IsPressed() and not active then
		self._Events:Push("Pressed", false)
	end
end

function Interactive:SetInactiveOverlayColour(colour)
	self._InactiveOverlayColour = colour
end

function Interactive:GetCanFocus()
	return self._CanFocus
end

function Interactive:SetCanFocus(canFocus)
	self._CanFocus = canFocus
end

function Interactive:IsFocused()
	return UserInterface.Focus == self
end

function Interactive:GetFocusedBackgroundColour()
	return self._FocusedBackgroundColour
end

function Interactive:GetFocusedColourMultiplier()
	return self._FocusedColourMultiplier
end

function Interactive:SetFocusedBackgroundColour(colour)
	self._FocusedBackgroundColour = colour
end

function Interactive:SetFocusedColourMultiplier(multiplier)
	self._FocusedColourMultiplier = multiplier
end

function Interactive:IsHovering()
	return UserInterface.Hovering == self
end

function Interactive:GetHoveringBackgroundColour()
	return self._HoveringBackgroundColour
end

function Interactive:GetHoveringColourMultiplier()
	return self._HoveringColourMultiplier
end

function Interactive:SetHoveringBackgroundColour(colour)
	self._HoveringBackgroundColour = colour
end

function Interactive:SetHoveringColourMultiplier(multiplier)
	self._HoveringColourMultiplier = multiplier
end

function Interactive:IsPressed()
	return UserInterface.CurrentlyPressed == self
end

function Interactive:GetPressedBackgroundColour()
	return self._PressedBackgroundColour
end

function Interactive:GetPressedColourMultiplier()
	return self._PressedColourMultiplier
end

function Interactive:SetPressedBackgroundColour(colour)
	self._PressedBackgroundColour = colour
end

function Interactive:SetPressedColourMultiplier(multiplier)
	self._PressedColourMultiplier = multiplier
end

function Interactive:Destroy()
	if not self._Destroyed then
		self._InactiveOverlayColour = nil
		self._FocusedBackgroundColour = nil
		self._HoveringBackgroundColour = nil
		self._PressedBackgroundColour = nil
		
		BASE_CLASS.Destroy(self)
	end
end

return Class.CreateClass(Interactive, "Interactive", BASE_CLASS)