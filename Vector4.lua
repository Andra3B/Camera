local Vector4 = {}

function Vector4.Create(x, y, z, w)
	local self = Class.CreateInstance(nil, Vector4)
	
	if type(x) == "number" then
		self.X = x
		self.Y = y or 0
		self.Z = z or 0
		self.W = w or 0
	else
		self.X = x.X
		self.Y = x.Y
		self.Z = x.Z or 0
		self.W = x.W or 0
	end
	
	return self
end

function Vector4:Lerp(otherVector, parameter)
	return Vector4.Create(
		self.X + parameter * (otherVector.X - self.X),
		self.Y + parameter * (otherVector.Y - self.Y),
		self.Z + parameter * (otherVector.Z - self.Z),
		self.W + parameter * (otherVector.W - self.W)
	)
end

function Vector4:Dot(otherVector)
	return
		self.X * otherVector.X +
		self.Y * otherVector.Y +
		self.Z * otherVector.Z +
		self.W * otherVector.W
end

function Vector4:SquaredMagnitude()
	return self.X^2 + self.Y^2 + self.Z^2 + self.W^2
end

function Vector4:Magnitude()
	return math.sqrt(self.X^2 + self.Y^2 + self.Z^2 + self.W^2)
end

function Vector4:Normalise()
	local inverseMagnitude = 1 / math.sqrt(self.X^2 + self.Y^2 + self.Z^2 + self.W^2)

	return Vector4.Create(
		self.X * inverseMagnitude,
		self.Y * inverseMagnitude,
		self.Z * inverseMagnitude,
		self.W * inverseMagnitude
	)
end

function Vector4:Unpack()
	return self.X, self.Y, self.Z, self.W
end

function Vector4.__add(leftVector, rightVector)
	local leftX, leftY, leftZ, leftW = leftVector:Unpack()
	local rightX, rightY, rightZ, rightW

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
		rightW = rightVector
	else
		rightX, rightY, rightZ, rightW = rightVector:Unpack()
	end

	return Vector4.Create(
		leftX + rightX,
		leftY + rightY,
		leftZ + rightZ,
		leftW + rightW
	)
end

function Vector4.__sub(leftVector, rightVector)
	local leftX, leftY, leftZ, leftW = leftVector:Unpack()
	local rightX, rightY, rightZ, rightW

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
		rightW = rightVector
	else
		rightX, rightY, rightZ, rightW = rightVector:Unpack()
	end

	return Vector4.Create(
		leftX - rightX,
		leftY - rightY,
		leftZ - rightZ,
		leftW - rightW
	)
end

function Vector4.__mul(leftVector, rightVector)
	local leftX, leftY, leftZ, leftW = leftVector:Unpack()
	local rightX, rightY, rightZ, rightW

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
		rightW = rightVector
	else
		rightX, rightY, rightZ, rightW = rightVector:Unpack()
	end

	return Vector4.Create(
		leftX * rightX,
		leftY * rightY,
		leftZ * rightZ,
		leftW * rightW
	)
end

function Vector4.__div(leftVector, rightVector)
	local leftX, leftY, leftZ, leftW = leftVector:Unpack()
	local rightX, rightY, rightZ, rightW

	if type(rightVector) == "number" then
		rightX = rightVector
		rightY = rightVector
		rightZ = rightVector
		rightW = rightVector
	else
		rightX, rightY, rightZ, rightW = rightVector:Unpack()
	end

	return Vector4.Create(
		leftX / rightX,
		leftY / rightY,
		leftZ / rightZ,
		leftW / rightW
	)
end

function Vector4.__unm(vector)
	local x, y, z, w = vector:Unpack()

	return Vector4.Create(-x, -y, -z, -w)
end

function Vector4.__eq(leftVector, rightVector)
	local leftX, leftY, leftZ, leftW = leftVector:Unpack()
	local rightX, rightY, rightZ, rightW = rightVector:Unpack()

	return leftX == rightX and leftY == rightY and leftZ == rightZ and leftW == rightW
end

function Vector4.__tostring(vector)
	return string.format("(%.3f, %.3f, %.3f, %.3f)", vector:Unpack())
end

Class.CreateClass(Vector4, "Vector4")

Vector4.Zero = Vector4.Create(0, 0, 0, 0)
Vector4.One = Vector4.Create(1, 1, 1, 1)

Vector4.Up = Vector4.Create(0, 1, 0, 0)
Vector4.Down = Vector4.Create(0, -1, 0, 0)
Vector4.Left = Vector4.Create(-1, 0, 0, 0)
Vector4.Right = Vector4.Create(1, 0, 0, 0)
Vector4.Forward = Vector4.Create(0, 0, 1, 0)
Vector4.Backward = Vector4.Create(0, 0, -1, 0)

return Class.CreateClass(Vector4, "Vector4")