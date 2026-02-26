local Timer = {}

local Timers = {}

function Timer.Update(deltaTime)
	for index, timer in pairs(Timers) do
		if not timer._Destroyed then
			if timer._Running then
				timer.Time = timer._Time + deltaTime

				if timer._Time >= timer._Duration then
					timer.Running = false
					timer._Events:Trigger("TimerElapsed")

					if timer._DestroyOnFinish then
						timer:Destroy()
						table.remove(Timers, index)
					end
				end
			end
		else
			timer:Destroy()
			table.remove(Timers, index)
		end
	end
end

function Timer.Create(duration, destroyOnFinish)
	local self = Class.CreateInstance(Entity.Create(), Timer)

	self._Duration = duration
	self._Time = 0

	self._Running = false

	self._Events = EventDirector.Create()

	if destroyOnFinish == nil then
		self._DestroyOnFinish = true
	else
		self._DestroyOnFinish = destroyOnFinish
	end

	table.insert(Timers, self)
	return self
end

function Timer:GetDuration()
	return self._Duration
end

function Timer:SetDuration(duration)
	self._Duration = duration

	self.Time = self._Time
end

function Timer:GetTime()
	return self._Time
end

function Timer:SetTime(time)
	self._Time = math.clamp(time, 0, self._Duration)
end

function Timer:IsRunning()
	return self._Running
end

function Timer:SetRunning(running)
	if self._Running ~= running then
		self._Running = running

		self._Events:Push(running and "TimerStarted" or "TimerStopped", self)
	end
end

function Timer:GetEvents()
	return self._Events
end

function Timer:Reset()
	self.Running = false
	self.Time = 0
end

function Timer:GetDestroyOnFinish()
	return self._DestroyOnFinish
end

function Timer:Destroy()
	if not self._Destroyed then
		self.Running = false

		self._Events:Destroy()
		self._Events = nil

		Entity.Destroy(self)
	end
end

function Timer.DestroyAllTimers()
	table.erase(Timers, Timer.Destroy)
end

return Class.CreateClass(Timer, "Timer", Entity)