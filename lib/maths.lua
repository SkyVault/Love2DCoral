function math.v2(x, y)
  return setmetatable({ _kind_ = "v2", x = x or 0, y = y or 0 }, {
    __tostring = function(self)
      return string.format("(%0.2f %0.2f)", self.x, self.y)
    end,

    __add = function(a, b)
      if type(b) == "table" then return math.v3(a.x + b.x, a.y + b.y)
      else return math.v2(a.x + b, a.y + b) end
    end,

    __sub = function(a, b)
      if type(b) == "table" then return math.v2(a.x - b.x, a.y - b.y)
      else return math.v2(a.x - b, a.y - b) end
    end,
  })
end

function math.v3(x, y, z)
  return setmetatable({ _kind_ = "v3", x = x or 0, y = y or 0, z = z or 0 }, {
    __tostring = function(self)
      return string.format("(%0.2f %0.2f %0.2f)", self.x, self.y, self.z)
    end,

    __add = function(a, b)
      if type(b) == "table" then return math.v3(a.x + b.x, a.y + b.y, a.z + b.z)
      else return math.v3(a.x + b, a.y + b, a.z + b) end
    end,

    __sub = function(a, b)
      if type(b) == "table" then return math.v3(a.x - b.x, a.y - b.y, a.z - b.z)
      else return math.v3(a.x - b, a.y - b, a.z - b) end
    end,
  })
end
