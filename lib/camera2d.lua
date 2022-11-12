return function(love, vault)
  local sin, cos = math.sin, math.cos

  return vault.table("camera-2d") {
    is_active = false,

    position = v2(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2),
    scale = 1,
    rotation = 0,

    look_at = function(self, x, y)
      self.position.x = -x
      self.position.y = -y
    end,

    move = function(self, dx, dy)
      self.position.x = self.position.x + dx
      self.position.y = self.position.y + dy
    end,

    rotate = function(self, θ) self.rotation = self.rotation + θ end,
    zoom = function(self, z) self.scale = self.scale * z end,

    start = function(self)
      local hw, hh = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
      love.graphics.push()
      love.graphics.translate(self.position.x + hw, self.position.y + hh)
      love.graphics.scale(self.scale)
      love.graphics.rotate(self.rotation)
    end,

    stop = function(self)
      love.graphics.pop()
    end,
  }
end
