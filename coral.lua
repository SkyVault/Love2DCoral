return function(base_path)
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

  local palette = _require("lib.palette")
  local pp = _require("lib.pprint")
  local tools = _require("lib.tools")
  local records = _require("lib.record")(pp)
  local sys = _require("lib.systems")
  local enums = _require("lib.enums")
  local art = _require("lib.artist")(enums.enum, sys, tools)

  local coral = records.record("Coral") {
    record = records.record,
    construct = records.construct,

    palette = palette,
    sys = sys,
    art = art,
    tools = tools,

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

  return coral
end
