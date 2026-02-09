local BASE_CLASS = ...
if not BASE_CLASS then error("Failed to create interative widget! BASE_CLASS not defined.", 2) end

local Frame = require("UserInterface.Frame")

local Interactive = {}

function Interactive.Create()
	local self = Class.CreateInstance(BASE_CLASS.Create(), Interactive)
	
	self._Active = true
	self._AbsoluteActive = nil

	self._FocusedBackgroundColour = Vector4.Create(0.9, 0.9, 0.9, 1)
	self._PressedBackgroundColour = Vector4.Create(1, 1, 1, 1)
	self._HoveringBackgroundColour = Vector4.Create(0, 0.9, 0.9, 1)

	return self
end

function Interactive:Refresh()
	BASE_CLASS.Refresh(self)

	self._AbsoluteActive = nil
end

function Interactive:GetBackgroundColour()
	if self.AbsoluteActive then
		if self:IsPressed() then
			return self:GetPressedBackgroundColour()
		elseif self:IsHovering() then
			return self:GetHoveringBackgroundColour()
		elseif self:IsFocused() then
			return self:GetFocusedBackgroundColour()
		end
	end
	
	return BASE_CLASS.GetBackgroundColour(self)
end

function Interactive:IsActive()
	return self._Active
end

function Interactive:GetAbsoluteActive()
	if self._AbsoluteActive == nil then
		local interactiveAncestor = self:GetAncestorWithType("Interactive")

		if interactiveAncestor then
			self._AbsoluteActive = interactiveAncestor._AbsoluteActive and self._Active
		else
			self._AbsoluteActive = self._Active
		end
	end

	return self._AbsoluteActive
end

function Interactive:SetActive(active)
	self._Active = active

	self:RecursiveRefresh()

	if self:IsPressed() and not active then
		self._Events:Push("Released")
	end
end

function Interactive:IsFocused()
	return UserInterface.Focus == self
end

function Interactive:GetFocusedBackgroundColour()
	return self._FocusedBackgroundColour
end

function Interactive:SetFocusedBackgroundColour(colour)
	self._FocusedBackgroundColour = colour
end

function Interactive:IsHovering()
	return UserInterface.Hovering == self
end

function Interactive:GetHoveringBackgroundColour()
	return self._HoveringBackgroundColour
end

function Interactive:SetHoveringBackgroundColour(colour)
	self._HoveringBackgroundColour = colour
end

function Interactive:IsPressed()
	return UserInterface.Pressed == self
end

function Interactive:GetPressedBackgroundColour()
	return self._PressedBackgroundColour
end

function Interactive:SetPressedBackgroundColour(colour)
	self._PressedBackgroundColour = colour
end

function Interactive:Destroy()
	if not self._Destroyed then
		self._FocusedBackgroundColour = nil
		self._HoveringBackgroundColour = nil
		self._PressedBackgroundColour = nil
		
		BASE_CLASS.Destroy(self)
	end
end

return Class.CreateClass(Interactive, "Interactive", BASE_CLASS)