local Frame = require("UserInterface.Frame")

local Pages = {}

Enum.PageTransitionDirection = Enum.Create({
	Up = 1,
	Down = 2,
	Left = 3,
	Right = 4
})

local function OnTransitionFinished(animation, pages)
	local oldPage = pages._OldPage
	local page = pages._Page

	local oldPageFrame = pages._Children[oldPage]

	if oldPageFrame then
		oldPageFrame.Visible = false
	end

	pages.ChildRelativeOffset = Vector2.Zero
	pages._OldPage = page
	
	if animation then
		animation:Reset()
	end

	pages._Events:Push("PageSwitching", oldPage, page, true)
end

local function OnChildAdded(self, _, child)
	child.PixelPosition = Vector2.Zero
	child.RelativePosition = Vector2.Zero

	child.Visible = #self._Children == 1
end

function Pages.Create()
	local self = Class.CreateInstance(Frame.Create(), Pages)

	self._Page = 1
	self._OldPage = 1

	self._PageTransitions = {}

	self._Events:Listen("ChildAdded", OnChildAdded)

	return self
end

function Pages:IsTransitioning()
	return self._Page ~= self._OldPage
end

function Pages:GetPlayingTransition()
	return self:GetTransition(self._OldPage, self._Page)
end

function Pages:GetPage()
	return self._Page
end

function Pages:SetPage(page)
	if page ~= self._Page and not self.Transitioning then
		local oldPage = self._Page
		local pageFrame = self._Children[page]
		
		if pageFrame then
			local oldPageFrame = self._Children[oldPage]
			local animation = self:GetTransition(oldPage, page)
				
			pageFrame.RelativePosition = Vector2.Zero
			pageFrame.Visible = true
			self._Page = page
			self._OldPage = oldPage

			if animation then
				oldPageFrame.RelativePosition = -animation.From
				self.ChildRelativeOffset = animation.From
					
				animation.Playing = true

				self._Events:Push("PageSwitching", oldPage, page, false)
			else
				self._Events:Push("PageSwitching", oldPage, page, false)
				OnTransitionFinished(nil, self)
			end

			return true, page
		end

		return false
	end
end

function Pages:GetTransition(from, to)
	local transitions = self._PageTransitions[from]

	if transitions then
		return transitions[to]
	end
end

function Pages:AddTransition(from, to, direction)
	local transitions = self._PageTransitions[from]

	if not transitions then
		if self._Children[from] then
			transitions = {}
			self._PageTransitions[from] = transitions
		else
			return false
		end
	end

	if to ~= from and self._Children[to] then
		if transitions[to] then
			transitions[to]:Destroy()
			transitions[to] = nil
		end

		if direction then
			local animation = Animation.Create(self, "ChildRelativeOffset", 
				direction == Enum.PageTransitionDirection.Up and Vector2.Create(0, 1) or
				direction == Enum.PageTransitionDirection.Down and Vector2.Create(0, -1) or
				direction == Enum.PageTransitionDirection.Left and Vector2.Create(1, 0) or
				Vector2.Create(-1, 0),
				Vector2.Zero,
				1,
				Enum.AnimationType.SharpSmoothStep,
				false
			)

			animation.Events:Listen("AnimationFinished", OnTransitionFinished, self)

			transitions[to] = animation

			return animation
		end
	else
		return false
	end
end

function Pages:RemoveTransition(from, to)
	local transitions = self._PageTransitions[from]

	if transitions then
		local animation = transitions[to]

		if animation then
			self._PageTransitions[from][to] = nil
			animation:Destroy()
		end
	end
end

function Pages:RemoveTransitions()
	for index, transitions in pairs(self._PageTransitions) do
		self._PageTransitions[index] = nil
		table.erase(transitions, Animation.Destroy)
	end
end

function Pages:Destroy()
	if not self._Destroyed then
		self:RemoveTransitions()
		self._PageTransitions = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(Pages, "Pages", Frame)