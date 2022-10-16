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

  local pp = _require("lib.pprint")
  local record = _require("lib.record")(pp)
  local sys = _require("lib.systems")

  local coral = record("Coral") {
    record = record,
    sys = sys,

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
