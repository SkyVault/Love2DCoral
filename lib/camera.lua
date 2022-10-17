local sqrt = math.sqrt
local PI = math.pi
local atan, cos, sin, max, abs = math.atan, math.cos, math.sin, math.max, math.abs

return function(love, record)
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  local Camera = record("camera") {
    fov = PI / 2,  -- 45.0 deg
    near = 0.01,
    far = 1000,
    aspect = aspect,
    position = v3(-2, 0, 1),
    target = v3(1, 0, 0),
    up = v3(0, 0, 1),

    view = m4(),
    projection = m4_projection(45.0, 0.0001, 1000.0, aspect),

    yaw = 0, -- math.pi/2,
    pitch = 0.0,

    yaw_and_pitch = function(self)
      return self.yaw, self.pitch
    end,

    look_vector = function(self)
      local v = self.target - self.position
      return v:magnitude() > 0 and v:normalized() or v
    end,

    look_at = function(self, position, target)
      self.position = position
      self.target = target

      local look = self:look_vector()
      self.yaw = PI/2 - atan(look.z, look.x)
      self.pitch = atan(look.y, sqrt(look.x ^ 2 + look.z ^ 2))

      self:update_view_matrix()
    end,

    look_in_direction = function(self, position, yaw, pitch)
      self.position = position or self.position

      self.yaw = yaw or self.yaw
      self.pitch = pitch or self.pitch

      local sign = cos(self.pitch)
      sign = (sign > 0 and 1) or (sign < 0 and -1) or 0

      local cpitch = sign * max(abs(cos(self.pitch)), 0.00001)

      self.target.x = self.position.x + cos(self.yaw) * cpitch
      self.target.y = self.position.y + sin(self.yaw) * cpitch
      self.target.z = self.position.z + sin(self.pitch)

      print(self.position)

      self:update_view_matrix()
    end,

    view_matrix = function(self)
      self.view = m4_view(self.position, self.target, self.up)
      return self.view
    end,

    update_view_matrix = function(self)
      self.view = m4_view(self.position, self.target, self.up)
    end,
  }

  return Camera
end
