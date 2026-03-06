local EventListener = require("EventListener")

local EventDirector = {}

function EventDirector.Create(source)
	local self = Class.CreateInstance(Entity.Create(), EventDirector)

	self._Queue = {}
    self._Listeners = {}

	self._Source = source

	return self
end

function EventDirector:GetSource()
	return self._Source
end

function EventDirector:GetListener(event, index)
	return self._Listeners[event][index]
end

function EventDirector:Push(event, ...)
    table.insert(self._Queue, 1, {event, ...})
end

function EventDirector:Listen(event, callback, userData, userDataCleanup)
    local eventListeners = self._Listeners[event]

    if not eventListeners then
        eventListeners = {}
        self._Listeners[event] = eventListeners
    end

    local eventListener = EventListener.Create(callback, userData, userDataCleanup)
    table.insert(eventListeners, eventListener)

    return #eventListeners + 1
end

function EventDirector:ClearQueue()
    table.erase(self._Queue)
end

function EventDirector:Update()
    while #self._Queue > 0 do
        self:Trigger(unpack(table.remove(self._Queue)))
    end
end

function EventDirector:Trigger(event, ...)
    local eventListeners = self._Listeners[event]

    if eventListeners then
        for index, eventListener in pairs(eventListeners) do
            if eventListener._Destroyed then
                eventListeners[index] = nil
			else
				eventListener:Trigger(self._Source, ...)
            end
        end
    end

	if self._Listeners.All then
		for index, eventListener in pairs(self._Listeners.All) do
			if eventListener._Destroyed then
				self._Listeners.All[index] = nil
			else
				eventListener:Trigger(self._Source, event, ...)
			end
		end
	end
end

function EventDirector:RemoveListeners(event)
	local eventListeners = self._Listeners[event]

	if eventListeners then
		for listenerIndex, eventListener in pairs(eventListeners) do
			eventListeners[listenerIndex] = nil
			eventListener:Destroy()
		end
	end
end

function EventDirector:Destroy()
	if not self._Destroyed then
		self:ClearQueue()
		self._Queue = nil

		for eventIndex, eventListeners in pairs(self._Listeners) do
			self._Listeners[eventIndex] = nil
			
        	for listenerIndex, eventListener in pairs(eventListeners) do
            	eventListeners[listenerIndex] = nil
            	eventListener:Destroy()
        	end
    	end
		
		self._Listeners = nil

		self._Source = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(EventDirector, "EventDirector", Entity)