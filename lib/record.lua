local function ext(a, b)
  setmetatable(a, getmetatable(b))
  for k, v in pairs(b) do
    if type(v) == "table" then
      a[k] = setmetatable(a[k] or {}, getmetatable(v))
      ext(a[k], v)
    else
      a[k] = v
    end
  end
  return a
end

return function(pp)
  local records = {}

  return function(name)
    return function(tbl)
      local r = ext(tbl, setmetatable({
        _name_ = name,
        _ctor_ = function(t)
          assert(t._name_ ~= nil)
          local r = records[t._name_]:name()
          return ext(r, t)
        end,
        new = function(self, d)
          return ext(self, d or {})
        end,
      }, {
        __tostring = function(self)
          return pp.pformat(self)
        end,
      }))

      records[r._name_] = r

      return r
    end
  end
end
