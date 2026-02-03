local Class = {}

Class.__index = Class
Class.Type = "Class"

local function IndexMetamethod(self, name)
	local getter = self.Class["Get"..name] or self.Class["Is"..name]

	if getter then
		return getter(self)
	else
		return self.Class[name]
	end
end

local function NewIndexMetamethod(self, name, value)
	local setter = self.Class["Set"..name]

	if setter then
		return setter(self, value)
	else
		rawset(self, name, value)
	end
end

function Class.CreateClass(class, typeName, base)
	base = base or Class
	
	for name, value in pairs(base) do
		if string.sub(name, 1, 2) == "__" and not class[name] then
			class[name] = value
		end
	end

	class.__index = class
	class.Type = typeName
	
	class.INSTANCE_METATABLE = {}
	class.CLASS_INDICATOR = true

	for name, value in pairs(class) do
		if string.sub(name, 1, 2) == "__" then
			class.INSTANCE_METATABLE[name] = value
		end
	end

	class.INSTANCE_METATABLE.__index = IndexMetamethod
	class.INSTANCE_METATABLE.__newindex = NewIndexMetamethod
	
	return setmetatable(class, base)
end

function Class.CreateInstance(instance, class)
	instance = instance or {}
	
	instance.Class = class
	instance.CLASS_INSTANCE_INDICATOR = true

	return setmetatable(instance, class.INSTANCE_METATABLE)
end

function Class:IsA(typeName)
	if type(self) == "table" and self.CLASS_INSTANCE_INDICATOR then
		for class in self:IterateInheritance() do
			if class.Type == typeName then
				return true
			end
		end

		return false
	end
	
	return Class.GetType(self) == typeName
end

function Class:GetType()
	local luaType = type(self)

	if luaType == "table" and self.CLASS_INDICATOR then
		return self.CLASS_INSTANCE_INDICATOR and self.Class.Type or self.Type
	end

	return luaType
end

local function InheritanceIterator(stopAt, currentClass)
	if currentClass.CLASS_INSTANCE_INDICATOR then
		return currentClass.Class
	else
		local nextClass = getmetatable(currentClass)

		if nextClass ~= stopAt then
			return nextClass
		end
	end
end

function Class:IterateInheritance(stopAt)
	return InheritanceIterator, stopAt, self
end

function Class.__tostring(entity)
	return entity.CLASS_INSTANCE_INDICATOR and entity.Class.Type.." Instance" or entity.Type.." Class"
end

return Class