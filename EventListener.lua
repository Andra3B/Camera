local EventListener = {}

function EventListener.Create(callback, userData, userDataCleanup)
	local self = Class.CreateInstance(Entity.Create(), EventListener)

	self._Callback = callback
    
    self._UserData = userData
    self._UserDataCleanup = userDataCleanup

	return self
end

function EventListener:Trigger(source, ...)
    if self._Callback(source, self._UserData, ...) then
        self:Destroy()
	end
end

function EventListener:GetCallback()
	return self._Callback
end

function EventListener:SetCallback(callback)
	if callback ~= self._Callback then
		self._Callback = callback

		return true, callback
	end
end

function EventListener:Destroy()
    if not self._Destroyed then
        self._Callback = nil

        if self._UserDataCleanup then
            self._UserDataCleanup(self._UserData)
        end

        self._UserData = nil
        self._UserDataCleanup = nil

        Entity.Destroy(self)
    end
end

return Class.CreateClass(EventListener, "EventListener", Entity)