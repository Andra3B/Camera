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
end

function Hierarchy:Refresh()
end

function Hierarchy:RecursiveRefresh()
	self:Refresh()

	for _, child in ipairs(self._Children) do
		child:RecursiveRefresh()
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

local function AcenstorIterator(parent)
	while parent do
		coroutine.yield(parent)

		parent = parent._Parent
	end
end

function Hierarchy:IterateAncestors()
	return coroutine.wrap(AcenstorIterator), self._Parent, nil
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

function Hierarchy:SetParent(parent)
	if self._Parent == parent then return true end

	if self._Parent then	
		for index, child in ipairs(self._Parent._Children) do
			if child == self then
				table.remove(self._Children, index)

				break
			end
		end
		
		self._Parent = nil
	end

	if parent then
		if parent ~= self and Class.IsA(parent, "Hierarchy") then
			self._Parent = parent

			table.insert(parent._Children, self)
			self:RecursiveRefresh()
		else
			return false
		end
	else
		self._Parent = nil
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

function Hierarchy:AddChild(child)
	return child:SetParent(self)
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