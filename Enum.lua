local Enum = {}

function Enum.Create(enums)
	local self = Class.CreateInstance(nil, Enum)

	for enum, value in pairs(enums) do
		self:Add(enum, value)
	end

	return self
end

function Enum:Add(enum, value)
	if not (self[enum] or self[value]) then
		self[enum] = value
		self[value] = enum

		return true
	end

	return false
end

local function EnumIterator(self, enum)
	local value

	repeat
		enum, value = next(self, enum)
	until not enum or type(enum) == "string"

	return enum, value
end

function Enum:Iterate()
	return EnumIterator, self, nil
end

return Class.CreateClass(Enum, "Enum")