local EventListener = require("EventListener")

local EventDirector = {}

function EventDirector.Create()
	local self = Class.CreateInstance(Entity.Create(), EventDirector)

	self._Queue = {}
    self._Listeners = {}

	return self
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

    return eventListener
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
            if eventListener._Destroyed or eventListener:Trigger(...) then
                eventListeners[index] = nil
            end
        end
    end

	if self._Listeners.All then
		for index, eventListener in pairs(self._Listeners.All) do
			if eventListener._Destroyed or eventListener:Trigger(event, ...) then
				eventListeners[index] = nil
			end
		end
	end
end


function EventDirector:Destroy()
	if not self._Destroyed then
		self:ClearQueue()
		self._Queue = nil

		for eventIndex, eventListeners in pairs(self._Listeners) do
        	for listenerIndex, eventListener in pairs(eventListeners) do
            	eventListener:Destroy()

            	eventListeners[listenerIndex] = nil
        	end

        	self._Listeners[eventIndex] = nil
    	end
		
		self._Listeners = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(EventDirector, "EventDirector", Entity)