local Sys = require "lib.systems"
local Pp = require "lib.pprint"
local Tools = require "lib.tools"

local record = Tools.record

local Coral = record("Coral") {
  current_profile = "game",

  sys = Sys,

  format = Pp.pformat,
  echo = Pp.pprint,

  internal = {
    dt = 0
  }
}

function Coral:bundle()
  return {
    sys = self.sys,
    current_profile = self.current_profile,
  }
end

function Coral:load()
  Sys.internal.load()
end

function Coral:update(dt)
  Sys.internal.update(dt)
  self.internal.dt = dt
end

function Coral:draw()
  Sys.internal.draw()
end

function Coral:save_game(profile)
  local path = (profile or self.current_profile or tostring(math.random())) .. "_save.lua"
  local f = io.open(path, "w")
  if f then
    f:write(string.format("return %s", Coral.format(self)))
    f:close()
  else
    error("Failed to open file: " .. path)
  end
end

function Coral:load_game(profile)
  local path = (profile or self.current_profile or tostring(math.random())) .. "_save"
  local data = require(path)
  if data then
    Tools.walk(data, function(_, value)
      if type(value) == "table" and value._name_ ~= nil then
        return Tools.init(value)
      end
      return value
    end)

    for k, v in pairs(data) do self[k] = v end
    for i, v in ipairs(data) do self[i] = v end
  else
    error("Failed to load game: "..profile)
  end
end

return Coral
