local Animation = {}

Enum.AnimationType = Enum.Create({
	Linear = 1,
	Cubic = 2,
	SmoothStep = 3,
	SharpSmoothStep = 4
})

local Animations = {}

local AnimationFunctions = {
	[Enum.AnimationType.Linear] = function(from, to, alpha)
		return from + (to - from)*alpha
	end,

	[Enum.AnimationType.Cubic] = function(from, to, alpha)
		return from + (to - from)*(1 - (1 - alpha)^3)
	end,

	[Enum.AnimationType.SmoothStep] = function(from, to, alpha)
		return from + (to - from)*(3*alpha^2 - 2*alpha^3)
	end,

	[Enum.AnimationType.SharpSmoothStep] = function(from, to, alpha)
		return from + (to - from)*(6*alpha^5 - 15*alpha^4 + 10*alpha^3)
	end
}

function Animation.Update(deltaTime)
	for index, animation in pairs(Animations) do
		if not (animation._Destroyed or animation._Object.Destroyed) then
			if animation._Playing then
				animation.Time = animation._Time + deltaTime

				if animation._Time < animation._Duration then
					local from = animation._From
					local to = animation._To

					local alpha = animation._Time / animation._Duration

					local propertyValue = animation._Object[animation._Property]
					local propertyType = Class.GetType(propertyValue)

					local animationFunction = AnimationFunctions[animation._AnimationType]

					if propertyType == "number" then
						animation._Object[animation._Property] = animationFunction(from, to, alpha)
					elseif propertyType == "Vector2" then
						animation._Object[animation._Property] = Vector2.Create(
							animationFunction(from.X, to.X, alpha),
							animationFunction(from.Y, to.Y, alpha)
						)
					elseif propertyType == "Vector3" then
						animation._Object[animation._Property] = Vector3.Create(
							animationFunction(from.X, to.X, alpha),
							animationFunction(from.Y, to.Y, alpha),
							animationFunction(from.Z, to.Z, alpha)
						)
					else
						animation._Object[animation._Property] = Vector4.Create(
							animationFunction(from.X, to.X, alpha),
							animationFunction(from.Y, to.Y, alpha),
							animationFunction(from.Z, to.Z, alpha),
							animationFunction(from.W, to.W, alpha)
						)
					end
				else
					animation._Object[animation._Property] = animation._To
					animation.Playing = false
					animation._Object.Events:Push("AnimationFinished", animation)

					if animation._DestroyOnFinish then
						animation:Destroy()
						table.remove(Animations, index)
					end
				end
			end
		else
			animation:Destroy()
			table.remove(Animations, index)
		end
	end
end

function Animation.Create(object, property, from, to, duration, animationType, destroyOnFinish)
	local self = Class.CreateInstance(Entity.Create(), Animation)

	self._Object = object
	self._Property = property
	self._PropertyType = Class.GetType(from)

	self._From = from
	self._To = to

	self._AnimationType = animationType

	self._Duration = duration
	self._Time = 0

	self._Playing = false

	if destroyOnFinish == nil then
		self._DestroyOnFinish = true
	else
		self._DestroyOnFinish = destroyOnFinish
	end

	table.insert(Animations, self)
	return self
end

function Animation:GetObject()
	return self._Object
end

function Animation:GetProperty()
	return self._Property
end

function Animation:GetFrom()
	return self._From
end

function Animation:GetTo()
	return self._To
end

function Animation:GetAnimationType()
	return self._AnimationType
end

function Animation:SetAnimationType(animationType)
	self._AnimationType = animationType
end

function Animation:GetDuration()
	return self._Duration
end

function Animation:SetDuration(duration)
	self._Duration = duration

	self.Time = self._Time
end

function Animation:GetTime()
	return self._Time
end

function Animation:SetTime(time)
	self._Time = math.clamp(time, 0, self._Duration)
end

function Animation:IsPlaying()
	return self._Playing
end

function Animation:SetPlaying(playing)
	if self._Playing ~= playing then
		self._Playing = playing

		if not self._Object.Destroyed then
			self._Object.Events:Push(playing and "AnimationStarted" or "AnimationStopped", self)
		end
	end
end

function Animation:Reset()
	self.Playing = false
	self.Time = 0
end

function Animation:GetDestroyOnFinish()
	return self._DestroyOnFinish
end

function Animation:Destroy()
	if not self._Destroyed then
		self.Playing = false

		self._Object[self._Property] = self._To

		self._Object = nil
		self._From = nil
		self._To = nil

		Entity.Destroy(self)
	end
end

function Animation.DestroyAllAnimations()
	table.erase(Animations, Animation.Destroy)
end

return Class.CreateClass(Animation, "Animation", Entity)