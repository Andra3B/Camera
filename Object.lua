local Object = {}

function Object.Create()
	local self = Class.CreateInstance(Entity.Create(), Object)

	self._Name = ""

	self._Parent = nil
	self._Children = {}

	self._Events = EventDirector.Create()

	return self
end

function Object:Update(deltaTime)
	self._Events:Update()
end

function Object:RecursiveUpdate(deltaTime)
	self:Update(deltaTime)

	for _, child in ipairs(self._Children) do
		child:RecursiveUpdate(deltaTime)
	end
end

function Object:Refresh()
end

function Object:RecursiveRefresh()
	self:Refresh()
	
	for _, child in ipairs(self._Children) do
		child:RecursiveRefresh()
	end
end

function Object:GetName()
	return self._Name
end

function Object:SetName(name)
	self._Name = tostring(name)
end

function Object:GetParent()
	return self._Parent
end

function Object:GetChildCount()
	return #self._Children
end

local function AncestorIterator(parent)
	while parent do
		coroutine.yield(parent)

		parent = parent._Parent
	end
end

function Object:IterateAncestors()
	return coroutine.wrap(AncestorIterator), self._Parent, nil
end

function Object:GetAncestorWithName(name)
	for ancestor in self:IterateAncestors() do
		if ancestor._Name == name then
			return ancestor
		end
	end
end

function Object:GetAncestorWithType(ancestorType)
	for ancestor in self:IterateAncestors() do
		if Class.IsA(ancestor, ancestorType) then
			return ancestor
		end
	end
end

function Object:SetParent(parent, where)
	if self._Parent then
		local parentChildren = self._Parent._Children

		for index, child in ipairs(parentChildren) do
			if child == self then
				table.remove(parentChildren, index)
	
				break
			end
		end
	end

	self._Parent = parent

	if parent then
		if parent ~= self and Class.IsA(parent, "Object") then
			local parentChildren = parent._Children

			table.insert(parentChildren, math.clamp(where or (#parentChildren + 1), 1, #parentChildren + 1), self)

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

function Object:GetChildren()
	return self._Children
end

function Object:GetChildWithName(name)
	for _, child in ipairs(self._Children) do
		if child._Name == name then
			return child
		end
	end
end

function Object:GetChildWithType(childType)
	for _, child in ipairs(self._Children) do
		if Class.IsA(child, childType) then
			return child
		end
	end
end

function Object:AddChild(child, where)
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

function Object:IterateDescendants()
	return coroutine.wrap(DescendantIterator), self, nil
end

function Object:GetDescendantWithName(name)
	for descendant in self:IterateDescendants() do
		if descendant._Name == name then
			return descendant
		end
	end
end

function Object:GetDescendantWithType(descendantType)
	for descendant in self:IterateDescendants() do
		if Class.IsA(descendant, descendantType) then
			return descendant
		end
	end
end

function Object:RemoveAllChildren()
	while #self._Children > 0 do
		self._Children[1]:SetParent(nil)
	end
end

function Object:RemoveChild(child)
	return child:SetParent(nil)
end

function Object:RemoveChildWithName(name)
	for _, child in ipairs(self._Children) do
		if child._Name == name then
			child:SetParent(nil)

			break
		end
	end
end

function Object:RemoveChildWithType(childType)
	for _, child in ipairs(self._Children) do
		if Class.IsA(child, childType) then
			child:SetParent(nil)

			break
		end
	end
end

function Object:GetEvents()
	return self._Events
end

function Object:Destroy()
	if not self._Destroyed then
		for _, child in ipairs(self._Children) do
			child:Destroy()
		end
		
		self:SetParent(nil)
		
		self._Events:Trigger("Destroyed")
		self._Events:Destroy()

		Entity.Destroy(self)
	end
end

return Class.CreateClass(Object, "Object", Entity)