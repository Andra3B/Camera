local Entity = {}

function Entity.Create()
	local self = Class.CreateInstance(nil, Entity)

	self._Destroyed = false

	return self
end

function Entity:IsDestroyed()
	return self._Destroyed
end

function Entity:Destroy()
	self._Destroyed = true
end

return Class.CreateClass(Entity, "Entity")