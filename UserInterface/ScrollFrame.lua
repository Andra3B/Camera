local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(
	require("UserInterface.Frame")
)

local ScrollFrame = {}

local function ScrollFrameInput(self, inputType, scancode, state)
	if scancode == "mousewheelmovement" then
		local container = self._Container

		if love.keyboard.isScancodeDown("lctrl") then
			container.ChildPixelOffset = Vector2.Create(container.ChildPixelOffset.X + state.Y*15, container.ChildPixelOffset.Y)
		else
			container.ChildPixelOffset = Vector2.Create(container.ChildPixelOffset.X, container.ChildPixelOffset.Y + state.Y*15)
		end
	end
end

local function VerticalScrollBarInput(self, inputType, scancode, state)
	if scancode == "leftmousebutton" then
		if state.Z < 0 then
			self._VerticalDragOffset = state.Y - self._VerticalScrollBar.AbsolutePosition.Y
		else
			self._VerticalDragOffset = nil
		end
	elseif scancode == "mousemovement" and self._VerticalDragOffset then
		local container = self._Container
		local absoluteChildTopLeftPosition = container.ChildAbsolutePosition
		local childAbsoluteSize = container.ChildAbsoluteSize
		local absoluteChildBottomRightY = absoluteChildTopLeftPosition.Y + childAbsoluteSize.Y
		local absoluteSize = container.AbsoluteSize

		local totalHeight = (absoluteChildTopLeftPosition.Y < 0 and absoluteChildBottomRightY < absoluteSize.Y) and (
			absoluteSize.Y - absoluteChildTopLeftPosition.Y
		) or (
			childAbsoluteSize.Y
		)

		container.ChildPixelOffset = Vector2.Create(
			container.ChildPixelOffset.X,
			((container.AbsolutePosition.Y + self._VerticalDragOffset - state.Y)/absoluteSize.Y)*totalHeight - absoluteChildTopLeftPosition.Y
		)
	end
end

local function HorizontalScrollBarInput(self, inputType, scancode, state)
	if scancode == "leftmousebutton" then
		if state.Z < 0 then
			self._HorizontalDragOffset = state.X - self._HorizontalScrollBar.AbsolutePosition.X
		else
			self._HorizontalDragOffset = nil
		end
	elseif scancode == "mousemovement" and self._HorizontalDragOffset then
		local container = self._Container
		local absoluteChildTopLeftPosition = container.ChildAbsolutePosition
		local childAbsoluteSize = container.ChildAbsoluteSize
		local absoluteChildBottomRightX = absoluteChildTopLeftPosition.X + childAbsoluteSize.X
		local absoluteSize = container.AbsoluteSize

		local totalWidth = (absoluteChildTopLeftPosition.X < 0 and absoluteChildBottomRightX < absoluteSize.X) and (
			absoluteSize.X - absoluteChildTopLeftPosition.X
		) or (
			childAbsoluteSize.X
		)

		container.ChildPixelOffset = Vector2.Create(
			((container.AbsolutePosition.X + self._HorizontalDragOffset - state.X)/absoluteSize.X)*totalWidth - absoluteChildTopLeftPosition.X,
			container.ChildPixelOffset.Y
		)
	end
end

function ScrollFrame.Create()
	local self = Class.CreateInstance(Interactive.Create(), ScrollFrame)

	self._CanFocus = false
	self._FocusedBackgroundColour = nil
	self._HoveringBackgroundColour = nil
	self._PressedBackgroundColour = nil

	self._Container = UserInterface.Frame.Create()
	self._Container.RelativeSize = Vector2.One
	self._Container.BackgroundColour = Vector4.Zero

	self._Overlay = UserInterface.Frame.Create()
	self._Overlay.RelativeSize = Vector2.One
	self._Overlay.BackgroundColour = Vector4.Zero

	self._VerticalScrollBar = UserInterface.Button.Create()
	self._VerticalScrollBar.RelativeOrigin = Vector2.Create(1, 0)
	self._VerticalScrollBar.PixelSize = Vector2.Create(10, 0)
	self._VerticalScrollBar.BackgroundColour = Vector4.Create(0.6, 0.6, 0.6, 0.8)
	self._VerticalScrollBar.FocusedBackgroundColour = Vector4.Create(0.6, 0.6, 0.6, 0.8)
	self._VerticalScrollBar.HoveringBackgroundColour = Vector4.Create(0.8, 0.8, 0.8, 0.8)
	self._VerticalScrollBar.PressedBackgroundColour = Vector4.Create(0.8, 0.8, 0.8, 0.8)
	self._VerticalScrollBar.CornerRelativeRadius = 1
	self._VerticalScrollBar.CanFocus = true
	self._VerticalScrollBar.Visible = false
	self._VerticalScrollBar.Parent = self._Overlay

	self._HorizontalScrollBar = UserInterface.Button.Create()
	self._HorizontalScrollBar.RelativeOrigin = Vector2.Create(0, 1)
	self._HorizontalScrollBar.PixelSize = Vector2.Create(0, 10)
	self._HorizontalScrollBar.BackgroundColour = Vector4.Create(0.6, 0.6, 0.6, 0.8)
	self._HorizontalScrollBar.FocusedBackgroundColour = Vector4.Create(0.6, 0.6, 0.6, 0.8)
	self._HorizontalScrollBar.HoveringBackgroundColour = Vector4.Create(0.8, 0.8, 0.8, 0.8)
	self._HorizontalScrollBar.PressedBackgroundColour = Vector4.Create(0.8, 0.8, 0.8, 0.8)
	self._HorizontalScrollBar.CornerRelativeRadius = 1
	self._HorizontalScrollBar.CanFocus = true
	self._HorizontalScrollBar.Visible = false
	self._HorizontalScrollBar.Parent = self._Overlay

	self._VerticalDragOffset = nil
	self._HorizontalDragOffset = nil

	self:AddChild(self._Container)
	self:AddChild(self._Overlay)

	self._Events:Listen("Input", ScrollFrameInput, self)
	self._VerticalScrollBar._Events:Listen("Input", VerticalScrollBarInput, self)
	self._HorizontalScrollBar._Events:Listen("Input", HorizontalScrollBarInput, self)

	return self
end

function ScrollFrame:Refresh()
	Interactive.Refresh(self)

	self._VerticalDragOffset = nil
	self._HorizontalDragOffset = nil
end

function ScrollFrame:GetContainer()
	return self._Container
end

function ScrollFrame:GetOverlay()
	return self._Overlay
end

function ScrollFrame:GetVerticalScrollBar()
	return self._VerticalScrollBar
end

function ScrollFrame:GetHorizontalScrollBar()
	return self._HorizontalScrollBar
end

function ScrollFrame:Draw()
	local container = self._Container

	self._VerticalScrollBar.Visible = false
	self._HorizontalScrollBar.Visible = false

	if #container._Children > 0 then
		local absoluteChildTopLeftPosition = container.ChildAbsolutePosition
		local childAbsoluteSize = container.ChildAbsoluteSize
		local absoluteChildBottomRightPosition = absoluteChildTopLeftPosition + childAbsoluteSize
		local childAbsoluteOffset = container.ChildAbsoluteOffset
		local absoluteSize = container.AbsoluteSize

		local verticalBarVisible = absoluteChildTopLeftPosition.Y < 0 or absoluteChildBottomRightPosition.Y > absoluteSize.Y
		local horizontalBarVisible = absoluteChildTopLeftPosition.X < 0 or absoluteChildBottomRightPosition.X > absoluteSize.X

		local viewX, viewY = 0, 0

		if verticalBarVisible then
			viewY = math.clamp(
				-childAbsoluteOffset.Y,
				math.min(absoluteChildTopLeftPosition.Y, 0),
				math.max(absoluteChildBottomRightPosition.Y - absoluteSize.Y, 0)
			)

			local totalHeight = (absoluteChildTopLeftPosition.Y < 0 and absoluteChildBottomRightPosition.Y < absoluteSize.Y) and (
				absoluteSize.Y - absoluteChildTopLeftPosition.Y
			) or (
				childAbsoluteSize.Y
			)

			if horizontalBarVisible then
				local horizontalBarAbsoluteSize = self._HorizontalScrollBar.AbsoluteSize

				self._VerticalScrollBar.RelativeSize = Vector2.Create(
					0, (absoluteSize.Y - horizontalBarAbsoluteSize.Y)/totalHeight
				)
				self._VerticalScrollBar.RelativePosition = Vector2.Create(
					1, (math.abs(viewY - absoluteChildTopLeftPosition.Y)/totalHeight)*(1 - (horizontalBarAbsoluteSize.Y/absoluteSize.Y))
				)
			else
				self._VerticalScrollBar.RelativeSize = Vector2.Create(
					0, absoluteSize.Y/totalHeight
				)
				self._VerticalScrollBar.RelativePosition = Vector2.Create(
					1, math.abs(viewY - absoluteChildTopLeftPosition.Y)/totalHeight
				)
			end
		end

		if horizontalBarVisible then
			viewX = math.clamp(
				-childAbsoluteOffset.X, 
				math.min(absoluteChildTopLeftPosition.X, 0),
				math.max(absoluteChildBottomRightPosition.X - absoluteSize.X, 0)
			)

			local totalWidth = (absoluteChildTopLeftPosition.X < 0 and absoluteChildBottomRightPosition.X < absoluteSize.X) and (
				absoluteSize.X - absoluteChildTopLeftPosition.X
			) or (
				childAbsoluteSize.X
			)

			if verticalBarVisible then
				local verticalBarAbsoluteSize = self._VerticalScrollBar.AbsoluteSize

				self._HorizontalScrollBar.RelativeSize = Vector2.Create(
					(absoluteSize.X - verticalBarAbsoluteSize.X)/totalWidth, 0
				)
				self._HorizontalScrollBar.RelativePosition = Vector2.Create(
					(math.abs(viewX - absoluteChildTopLeftPosition.X)/totalWidth)*(1 - (verticalBarAbsoluteSize.X/absoluteSize.X)), 1
				)
			else
				self._HorizontalScrollBar.RelativeSize = Vector2.Create(
					absoluteSize.X/totalWidth, 0
				)
				self._HorizontalScrollBar.RelativePosition = Vector2.Create(
					math.abs(viewX - absoluteChildTopLeftPosition.X)/totalWidth, 1
				)
			end
		end

		self._VerticalScrollBar.Visible = verticalBarVisible
		self._HorizontalScrollBar.Visible = horizontalBarVisible

		container.ChildPixelOffset = Vector2.Create(-viewX, -viewY)
	end

	Interactive.Draw(self)
end

function ScrollFrame:Destroy()
	if not self._Destroyed then
		self._Container = nil
		self._Overlay = nil
		self._HorizontalScrollBar = nil
		self._VerticalScrollBar = nil

		Interactive.Destroy(self)
	end
end

return Class.CreateClass(ScrollFrame, "ScrollFrame", Interactive)