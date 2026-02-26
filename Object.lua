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

function Object:RecursiveRefresh(fromRoot)
	if fromRoot then
		self.Root:RecursiveRefresh(false)
	else
		self:Refresh()
		
		for _, child in ipairs(self._Children) do
			child:RecursiveRefresh(false)
		end
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

function Object:GetRoot()
	local object = self

	while object._Parent do
		object = object._Parent
	end

	return object
end

function Object:SetParent(parent, where)
	if parent then
		return parent:AddChild(self, where)
	elseif self._Parent then
		self._Parent:RemoveChild(self)
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
	if Class.IsA(child, "Object") then
		where = math.clamp(where or (#self._Children + 1), 1, #self._Children + 1)

		if child._Parent == self then
			for index, currentChild in ipairs(self._Children) do
				if child == currentChild then
					if index == where then
						return true
					else
						table.remove(self._Children, index)
					end

					break
				end
			end
		else
			child.Parent = nil
		end

		child._Parent = self
		table.insert(self._Children, where, child)
		
		return true
	end

	return false
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
	for index, child in ipairs(self._Children) do
		self._Children[index] = nil
		child._Parent = nil
	end
end

function Object:RemoveChild(child)
	for index, currentChild in ipairs(self._Children) do
		if currentChild == child then
			table.remove(self._Children, index)
			child._Parent = nil

			break
		end
	end
end

function Object:RemoveChildWithName(name)
	for index, child in ipairs(self._Children) do
		if child._Name == name then
			table.remove(self._Children, index)
			child._Parent = nil

			break
		end
	end
end

function Object:RemoveChildWithType(childType)
	for index, child in ipairs(self._Children) do
		if Class.IsA(child, childType) then
			table.remove(self._Children, index)
			child._Parent = nil

			break
		end
	end
end

function Object:GetEvents()
	return self._Events
end

function Object:Destroy()
	if not self._Destroyed then
		for index, child in ipairs(self._Children) do
			table.remove(self._Children, index)
			child:Destroy()
		end
		
		self.Parent = nil

		self._Events:Destroy()

		Entity.Destroy(self)
	end
end

return Class.CreateClass(Object, "Object", Entity)