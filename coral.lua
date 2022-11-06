local base_path = (...):match('^(.*[%./])[^%.%/]+$') or ''

return function(love)
  love = love or _G["love"]

  assert(love, "Missing love")

  local function _require(loc)
    local b = base_path or ""
    if b ~= "" then loc = b .. loc end
    local function try_require(p)
      local ok, value = pcall(function() return require(p) end)
      if ok then return value else return nil end
    end

    return try_require(loc)
  end

  local function hash(v)
    return love.data.encode("string", "hex", love.data.hash("md5", tostring(v)))
  end

  local function create_coral()
    local vault = _require("lib.vault")

    _require("lib.maths")(vault)

    local palette = _require("lib.palette")
    local pp = _require("lib.pprint")
    local tools = _require("lib.tools")

    local camera = _require("lib.camera")(love, vault)
    local camera2d = _require("lib.camera2d")(love, vault)

    local game_camera = camera:new {  }

    local sys = _require("lib.systems")
    local enums = _require("lib.enums")
    local actors = _require("lib.actors")(tools, vault)
    local art = _require("lib.artist")(love, enums.enum, sys, tools, game_camera, pp, vault)
    local timers = _require("lib.timers")(sys)
    local clock = _require("lib.clock")(vault)
    local input = _require("lib.input")(love, sys, tools.set)
    local ui = _require("lib.ui")(love, sys, art, tools, input, vault, palette)
    local watch = _require("lib.watchers")(sys, ui, hash)
    local tween = _require("lib.tweens")(sys, tools)
    local assets = _require("lib.assets")(love)

    return vault.table("Coral") {
      vault = vault,
      palette = palette,
      sys = sys,
      art = art,
      tools = tools,
      actors = actors,
      enums = enums,
      timers = timers,
      camera = game_camera,
      ui = ui,
      input = input,
      tween = tween,
      assets = assets,
      watch = watch,

      camera2d = camera2d,

      hash = hash,

      clock = clock:new(),

      print = pp.pprint,
      format = pp.pformat,
      timer = timers.timer,
    }
  end

  local coral = create_coral()

  function coral:load()
    self.sys.internal.load()
  end

  function coral:update(dt)
    self.clock:update(dt)
    self.sys.internal.update(dt)
  end

  function coral:draw()
    self.sys.internal.draw()
  end

  function coral:keypressed(k)
    self.sys.internal.keypressed(k)
  end

  function coral:keyreleased(k)
    self.sys.internal.keyreleased(k)
  end

  local ks = {}
  for k, _ in pairs(love) do
    table.insert(ks, k)
  end

  local _love = {}

  love.load = function()
    coral:load()

    if _love.load then
      _love.load()
    end
  end

  love.update = function(dt)
    coral:update(dt)

    if _love.update then
      _love.update(dt)
    end
  end

  love.draw = function()
    coral:draw()

    if _love.draw then
      _love.draw()
    end
  end

  love.conf = function(t) _love.conf(t) end

  love.keypressed = function(k)
    coral:keypressed(k)
    if _love.keypressed then
      _love.keypressed()
    end
  end

  love.keyreleased = function(k)
    coral:keyreleased(k)
    if _love.keyreleased then
      _love.keyreleased()
    end
  end

  love.resize = function(w, h)
    coral.art.resize(w, h)
  end

  _G["love"] = _love
  for i = 1, #ks do
    _G["love"][ks[i]] = love[ks[i]]
  end

  -- in the very rare case that the user adds a metatable to the love object,
  -- a usecase would be to spy on what is getting called or something.
  setmetatable(_G["love"], getmetatable(love))

  return coral
end
