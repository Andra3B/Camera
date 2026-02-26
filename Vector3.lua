local Vector3 = {}

function Vector3.Create(x, y, z)
	local self = Class.CreateInstance(nil, Vector3)
	
	if type(x) == "number" then
		self.X = x
		self.Y = y or 0
		self.Z = z or 0
	else
		self.X = x.X
		self.Y = x.Y
		self.Z = x.Z or 0
	end
	
	return self
end

function Vector3:Lerp(otherVector, parameter)
	return Vector3.Create(
		self.X + parameter * (otherVector.X - self.X),
		self.Y + parameter * (otherVector.Y - self.Y),
		self.Z + parameter * (otherVector.Z - self.Z)
	)
end

function Vector3:Dot(otherVector)
	return
		self.X * otherVector.X +
		self.Y * otherVector.Y +
		self.Z * otherVector.Z
end

function Vector3:Cross(otherVector)
	local selfX, selfY, selfZ = self:Unpack()
	local x, y, z = otherVector:Unpack()

	return Vector3.Create(
		selfY*z - selfZ*y,
		selfZ*x - selfX*z,
		selfX*y - selfY*x
	)
end

function Vector3:SquaredMagnitude()
	return self.X^2 + self.Y^2 + self.Z^2
end

function Vector3:Magnitude()
	return math.sqrt(self.X^2 + self.Y^2 + self.Z^2)
end

function Vector3:Normalise()
	local inverseMagnitude = 1 / math.sqrt(self.X^2 + self.Y^2 + self.Z^2)

	return Vector3.Create(
		self.X * inverseMagnitude,
		self.Y * inverseMagnitude,
		self.Z * inverseMagnitude
	)
end

function Vector3:Unpack()
	return self.X, self.Y, self.Z
end

function Vector3.__add(leftVector, rightVector)
	local leftX, leftY, leftZ = leftVector:Unpack()
	local rightX, rightY, rightZ

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
	else
		rightX, rightY, rightZ = rightVector:Unpack()
	end

	return Vector3.Create(
		leftX + rightX,
		leftY + rightY,
		leftZ + rightZ
	)
end

function Vector3.__sub(leftVector, rightVector)
	local leftX, leftY, leftZ = leftVector:Unpack()
	local rightX, rightY, rightZ

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
	else
		rightX, rightY, rightZ = rightVector:Unpack()
	end

	return Vector3.Create(
		leftX - rightX,
		leftY - rightY,
		leftZ - rightZ
	)
end

function Vector3.__mul(leftVector, rightVector)
	local leftX, leftY, leftZ = leftVector:Unpack()
	local rightX, rightY, rightZ

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
	else
		rightX, rightY, rightZ = rightVector:Unpack()
	end

	return Vector3.Create(
		leftX * rightX,
		leftY * rightY,
		leftZ * rightZ
	)
end

function Vector3.__div(leftVector, rightVector)
	local leftX, leftY, leftZ = leftVector:Unpack()
	local rightX, rightY, rightZ

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
	else
		rightX, rightY, rightZ = rightVector:Unpack()
	end

	return Vector3.Create(
		leftX / rightX,
		leftY / rightY,
		leftZ / rightZ
	)
end

function Vector3.__unm(vector)
	local x, y, z = vector:Unpack()

	return Vector3.Create(-x, -y, -z)
end

function Vector3.__eq(leftVector, rightVector)
	local leftX, leftY, leftZ = leftVector:Unpack()
	local rightX, rightY, rightZ = rightVector:Unpack()

	return leftX == rightX and leftY == rightY and leftZ == rightZ
end

function Vector3.__tostring(vector)
	return string.format("(%.3f, %.3f, %.3f)", vector:Unpack())
end

Class.CreateClass(Vector3, "Vector3")

Vector3.Zero = Vector3.Create(0, 0, 0)
Vector3.One = Vector3.Create(1, 1, 1)

Vector3.Up = Vector3.Create(0, 1, 0)
Vector3.Down = Vector3.Create(0, -1, 0)
Vector3.Left = Vector3.Create(-1, 0, 0)
Vector3.Right = Vector3.Create(1, 0, 0)
Vector3.Forward = Vector3.Create(0, 0, 1)
Vector3.Backward = Vector3.Create(0, 0, -1)

return Class.CreateClass(Vector3, "Vector3")