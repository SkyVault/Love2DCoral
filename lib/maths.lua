local sin = math.sin
local cos = math.cos
local tan = math.tan

function v2(x, y)
  return setmetatable({ _kind_ = "v2", x = x or 0, y = y or 0 }, {
    __tostring = function(self)
      return string.format("(%0.2f %0.2f)", self.x, self.y)
    end,

    __add = function(a, b)
      if type(b) == "table" then return v3(a.x + b.x, a.y + b.y)
      else return v2(a.x + b, a.y + b) end
    end,

    __sub = function(a, b)
      if type(b) == "table" then return v2(a.x - b.x, a.y - b.y)
      else return v2(a.x - b, a.y - b) end
    end,
  })
end

function v3(x, y, z)
  return setmetatable({
    _kind_ = "v3", x = x or 0, y = y or 0, z = z or 0,
    magnitude = function(self)
      return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ z)
    end,
    normalized = function(self)
      local mag = self:magnitude()
      return mag == 0 and v3() or v3(self.x / mag, self.y / mag, self.z / mag)
    end,
    dot = function(self, other)
      return self.x * other.x + self.y * other.y + self.z * other.z
    end,
    cross = function(self, other)
      return v3(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
      )
    end,
    scaler_mult = function(sc, a, b, c)
      return a*sc, b*sc, c*sc
    end,
  }, {
    __tostring = function(self)
      return string.format("(%0.2f %0.2f %0.2f)", self.x, self.y, self.z)
    end,

    __add = function(a, b)
      if type(b) == "table" then return v3(a.x + b.x, a.y + b.y, a.z + b.z)
      else return v3(a.x + b, a.y + b, a.z + b) end
    end,

    __sub = function(a, b)
      if type(b) == "table" then return v3(a.x - b.x, a.y - b.y, a.z - b.z)
      else return v3(a.x - b, a.y - b, a.z - b) end
    end,

    _mul = function(a, b)
      if type(b) == "table" then return v3(a.x * b.x, a.y * b.y, a.z * b.z)
      else return v3(a.x * b, a.y * b, a.z * b) end
    end,
  })
end

function m4()
  local m = setmetatable({
    _kind_ = "m4",
    m = { }
  }, {
    --__tostring = function(self)
      --return "%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f":format(table.unpack(self))
    --end,
  })
  m.m[ 1], m.m[ 2], m.m[ 3], m.m[ 4] = 1, 0, 0, 0
  m.m[ 5], m.m[ 6], m.m[ 7], m.m[ 8] = 0, 1, 0, 0
  m.m[ 9], m.m[10], m.m[11], m.m[12] = 0, 0, 1, 0
  m.m[13], m.m[14], m.m[15], m.m[16] = 0, 0, 0, 1
  return m
end

function m4_transform(translation, rotation, scale)
  local m = m4()
  m.m[ 4] = translation.x
  m.m[ 8] = translation.y
  m.m[12] = translation.z

  if rotation._kind_ == "v3" then
    local ca, cb, cc = cos(rotation.z), cos(rotation.y), cos(rotation.x)
    local sa, sb, sc = sin(rotation.z), sin(rotation.y), sin(rotation.x)
    m.m[1], m.m[ 2], m.m[ 3] = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc
    m.m[5], m.m[ 6], m.m[ 7] = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc
    m.m[9], m.m[10], m.m[11] = -sb, cb*sc, cb*cc

    -- todo quaternion
  else
    error("Invalid rotation type, expected v3")
  end

  -- scale
  local sx, sy, sz = scale.x, scale.y, scale.z
  m.m[1], m.m[ 2], m.m[ 3] = m.m[1] * sx, m.m[ 2] * sy, m.m[ 3] * sz
  m.m[5], m.m[ 6], m.m[ 7] = m.m[5] * sx, m.m[ 6] * sy, m.m[ 7] * sz
  m.m[9], m.m[10], m.m[11] = m.m[9] * sx, m.m[10] * sy, m.m[11] * sz

  m.m[13], m.m[14], m.m[15], m.m[16] = 0, 0, 0, 1

  return m
end

function m4_projection(fov, near, far, aspect_ratio)
  local m = m4()
  local top = near * tan(fov/2)
  local bottom = -1 * top
  local right = top * aspect_ratio
  local left = -1 * right

  m.m[1],  m.m[2],  m.m[3],  m.m[4]  = 2*near/(right-left), 0, (right+left)/(right-left), 0
  m.m[5],  m.m[6],  m.m[7],  m.m[8]  = 0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0
  m.m[9],  m.m[10], m.m[11], m.m[12] = 0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near)
  m.m[13], m.m[14], m.m[15], m.m[16] = 0, 0,  -1, 0

  return m
end

function m4_view(eye, target, up)
  local m = m4()

  local z = v3(eye.x - target.x, eye.y - target.y, eye.z - target.z):normalized()
  local x = up:cross(z):normalized()
  local y = z:cross(x)

  m.m[ 1], m.m[ 2], m.m[ 3], m.m[ 4] = x.x, x.y, x.z, -1 * x:dot(eye)
  m.m[ 5], m.m[ 6], m.m[ 7], m.m[ 8] = y.x, y.y, y.z, -1 * y:dot(eye)
  m.m[ 9], m.m[10], m.m[11], m.m[12] = z.x, z.y, z.z, -1 * z:dot(eye)
  m.m[13], m.m[14], m.m[15], m.m[16] = 0, 0, 0, 1

  return m
end
