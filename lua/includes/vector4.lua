local __Vector4 = {}
__Vector4.__index = __Vector4

function __Vector4:__eq(Other)
	return self.x == Other.x and self.y == Other.y and self.z == Other.z and self.w == Other.w
end

function __Vector4:__lt(Other, UseValues)
	if UseValues then
		return self.x < Other.x and self.y < Other.y and self.z < Other.z and self.w < Other.w
	else
		return self:Length() < Other:Length()
	end
end

function __Vector4:__le(Other)
	return self:__lt(Other) or self:__eq(Other)
end

-- Helper things
function __Vector4:LengthSqr()
	return (self.x * self.x) + (self.y + self.y) + (self.z * self.z) + (self.w * self.w)
end

function __Vector4:Length()
	return math.sqrt(self:LengthSqr())
end

function __Vector4:IsZero(Tolerance)
	Tolerance = tonumber(Tolerance) or 0.01

	if self.x > -Tolerance and self.x < Tolerance then return true end
	if self.y > -Tolerance and self.y < Tolerance then return true end
	if self.z > -Tolerance and self.z < Tolerance then return true end
	if self.w > -Tolerance and self.w < Tolerance then return true end

	return false
end

function __Vector4:Zero()
	self.x = 0
	self.y = 0
	self.z = 0
	self.w = 0

	return self -- Allow chaining
end

function __Vector4:Add(Other)
	self.x = self.x + Other.x
	self.y = self.y + Other.y
	self.z = self.z + Other.z
	self.w = self.w + Other.w

	return self
end

function __Vector4:Sub(Other)
	self.x = self.x - Other.x
	self.y = self.y - Other.y
	self.z = self.z - Other.z
	self.w = self.w - Other.w

	return self
end

function __Vector4:Mul(Other)
	self.x = self.x * Other.x
	self.y = self.y * Other.y
	self.z = self.z * Other.z
	self.w = self.w * Other.w

	return self
end

function __Vector4:Div(Other)
	self.x = self.x / Other.x
	self.y = self.y / Other.y
	self.z = self.z / Other.z
	self.w = self.w / Other.w

	return self
end

-- Make new one
function Vector4(x, y, z, w)
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	z = tonumber(z) or 0
	w = tonumber(w) or 0

	local NewVector4 = setmetatable({
		x = x,
		y = y,
		z = z,
		w = w
	}, __Vector4)

	return NewVector4
end

RegisterMetaTable("Vector4", __Vector4)
