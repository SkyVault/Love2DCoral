return function(base_path, love)
  love = love or _G["love"]

  assert(love, "Missing love")

  local function _require(loc)
    local b = base_path or ""
    if b ~= "" then
      loc = b .. "." .. loc
    end

    local function try_require(p)
      local ok, value = pcall(function() return require(p) end)
      if ok then return value else return nil end
    end

    return try_require(loc) or try_require("lib.Coral." .. loc) or try_require("Coral." .. loc)
  end

  _require("lib.maths")

  local palette = _require("lib.palette")
  local pp = _require("lib.pprint")
  local tools = _require("lib.tools")
  local records = _require("lib.record")(pp)
  local sys = _require("lib.systems")
  local enums = _require("lib.enums")
  local actors = _require("lib.actors")(tools)
  local art = _require("lib.artist")(love, enums.enum, sys, tools)

  local coral = records.record("Coral") {
    record = records.record,
    construct = records.construct,

    palette = palette,
    sys = sys,
    art = art,
    tools = tools,
    actors = actors,
    enums = enums,

    print = pp.pprint,
    format = pp.pformat,
  }

  function coral:load()
    self.sys.internal.load()
  end

  function coral:update(dt)
    self.sys.internal.update(dt)
  end

  function coral:draw()
    self.sys.internal.draw()
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

  _G["love"] = _love
  for i = 1, #ks do
    _G["love"][ks[i]] = love[ks[i]]
  end

  -- in the very rare case that the user adds a metatable to the love object,
  -- a usecase would be to spy on what is getting called or something.
  setmetatable(_G["love"], getmetatable(love))

  return coral
end
