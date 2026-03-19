local Object = {}

local function NewIndexMetamethod(self, name, value)
	local setter = self.Class["Set"..name]

	if setter then
		local set, setValue = setter(self, value)

		if set and not self._Destroyed then
			self._Events:Trigger(name.."Changed", setValue)

			if self._Parent then
				self._Parent._Events:Trigger("Child"..name.."Changed", self, setValue)
			end

			for _, child in ipairs(self._Children) do
				child._Events:Trigger("Parent"..name.."Changed", setValue)
			end
		end
	else
		rawset(self, name, value)
	end
end

function Object.Create(object)
	local self = Class.CreateInstance(Entity.Create(), Object)

	self._Name = ""

	self._Parent = nil
	self._Children = {}

	self._Events = EventDirector.Create(self)

	if object then
		self.Name = object.Name
	end

	return self
end

function Object:Refresh()
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

function Object:GetName()
	return self._Name
end

function Object:SetName(name)
	name = tostring(name)

	if name ~= self._Name then
		self._Name = name

		return true, self._Name
	end
end

function Object:GetParent()
	return self._Parent
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
	if parent ~= self._Parent then
		if self._Parent then
			for index, currentChild in pairs(self._Parent._Children) do
				if currentChild == self then
					table.remove(self._Parent._Children, index)

					self._Parent.Events:Trigger("ChildRemoved", self)
					self._Parent = nil

					break
				end
			end
		end

		if parent then
			table.insert(parent._Children, math.clamp(where or (#parent._Children + 1), 1, #parent._Children + 1), self)
			self._Parent = parent

			parent.Events:Trigger("ChildAdded", self)
		end

		return true, parent
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

local function DescendantIterator(children)
	for _, child in ipairs(children) do
		coroutine.yield(child)
		DescendantIterator(child._Children)
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

function Object:RemoveChildren()
	while #self._Children > 0 do
		self._Children[1].Parent = nil
	end
end

function Object:DestroyChildren()
	while #self._Children > 0 do
		local child = self._Children[1]

		child.Parent = nil
		child:Destroy()
	end
end

function Object:GetEvents()
	return self._Events
end

function Object:Destroy()
	if not self._Destroyed then
		self:DestroyChildren()

		self._Parent = nil

		self._Events:Trigger("Destroyed")
		self._Events:Destroy()
		
		Entity.Destroy(self)
	end
end

return Class.CreateClass(Object, "Object", Entity, nil, NewIndexMetamethod)