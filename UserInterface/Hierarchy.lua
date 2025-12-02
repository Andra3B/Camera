local Hierarchy = {}

function Hierarchy.Create()
	local self = Class.CreateInstance(nil, Hierarchy)

	self._Name = ""

	self._Parent = nil
	self._Children = {}

	self._Events = EventDirector.Create()

	self._Destroyed = false

	return self
end

function Hierarchy:Update(deltaTime)
	self._Events:Update()
end

function Hierarchy:RecursiveUpdate(deltaTime)
	self:Update(deltaTime)

	for _, child in ipairs(self._Children) do
		child:RecursiveUpdate(deltaTime)
	end

	if self._Children[0] then
		self._Children[0]:RecursiveUpdate(deltaTime)
	end
end

function Hierarchy:Refresh()
end

function Hierarchy:RecursiveRefresh()
	self:Refresh()
	
	for _, child in ipairs(self._Children) do
		child:RecursiveRefresh()
	end

	if self._Children[0] then
		self._Children[0]:RecursiveRefresh()
	end
end

function Hierarchy:GetName()
	return self._Name
end

function Hierarchy:SetName(name)
	self._Name = tostring(name)
end

function Hierarchy:GetParent()
	return self._Parent
end

function Hierarchy:GetChildCount()
	return #self._Children
end

local function AncestorIterator(parent)
	while parent do
		coroutine.yield(parent)

		parent = parent._Parent
	end
end

function Hierarchy:IterateAncestors()
	return coroutine.wrap(AncestorIterator), self._Parent, nil
end

function Hierarchy:GetAncestorWithName(name)
	for ancestor in self:IterateAncestors() do
		if ancestor._Name == name then
			return ancestor
		end
	end
end

function Hierarchy:GetAncestorWithType(ancestorType)
	for ancestor in self:IterateAncestors() do
		if Class.IsA(ancestor, ancestorType) then
			return ancestor
		end
	end
end

function Hierarchy:SetParent(parent, where)
	if self._Parent then
		local parentChildren = self._Parent._Children

		if parentChildren[0] == self then
			parentChildren[0] = nil
		else
			for index, child in ipairs(parentChildren) do
				if child == self then
					table.remove(parentChildren, index)
	
					break
				end
			end
		end
	end

	self._Parent = parent

	if parent then
		if parent ~= self and Class.IsA(parent, "Hierarchy") then
			local parentChildren = parent._Children

			if where == 0 then
				if parentChildren[0] then
					parentChildren[0]:SetParent(nil)
				end

				parentChildren[0] = self
			else
				table.insert(parentChildren, math.clamp(where or (#parentChildren + 1), 0, #parentChildren + 1), self)
			end

			self:RecursiveRefresh()
		else
			return false
		end
	end
	
	return true
end

local function ChildIterator(children)
	for _, child in ipairs(children) do
		coroutine.yield(child)
	end
end

function Hierarchy:GetChildren()
	return self._Children
end

function Hierarchy:GetChildWithIndex(index)
	return self._Children[index]
end

function Hierarchy:GetChildWithName(name)
	for _, child in ipairs(self._Children) do
		if child._Name == name then
			return child
		end
	end
end

function Hierarchy:GetChildWithType(childType)
	for _, child in ipairs(self._Children) do
		if Class.IsA(child, childType) then
			return child
		end
	end
end

function Hierarchy:AddChild(child, where)
	return child:SetParent(self, where)
end

local function DescendantIterator(children)
	for _, child in ipairs(children) do
		coroutine.yield(child)

		if child._Children then
			DescendantIterator(child._Children)
		end
	end
end

function Hierarchy:IterateDescendants()
	return coroutine.wrap(DescendantIterator), self, nil
end

function Hierarchy:GetDescendantWithName(name)
	for descendant in self:IterateDescendants() do
		if descendant._Name == name then
			return descendant
		end
	end
end

function Hierarchy:GetDescendantWithType(descendantType)
	for descendant in self:IterateDescendants() do
		if Class.IsA(descendant, descendantType) then
			return descendant
		end
	end
end

function Hierarchy:RemoveAllChildren()
	while #self._Children > 0 do
		self._Children[1]:SetParent(nil)
	end
end

function Hierarchy:RemoveChild(child)
	return child:SetParent(nil)
end

function Hierarchy:RemoveChildWithName(name)
	for _, child in ipairs(self._Children) do
		if child._Name == name then
			child:SetParent(nil)

			break
		end
	end
end

function Hierarchy:RemoveChildWithType(childType)
	for _, child in ipairs(self._Children) do
		if Class.IsA(child, childType) then
			child:SetParent(nil)

			break
		end
	end
end

function Hierarchy:GetEvents()
	return self._Events
end

function Hierarchy:IsDestroyed()
	return self._Destroyed
end

function Hierarchy:Destroy()
	if not self._Destroyed then
		if self._Children[0] then
			self._Children[0]:Destroy()
		end

		for _, child in ipairs(self._Children) do
			child:Destroy()
		end
		
		self:SetParent(nil)
		
		self._Events:Trigger("Destroyed")
		self._Events:Destroy()

		self._Destroyed = true
	end
end

return Class.CreateClass(Hierarchy, "Hierarchy")