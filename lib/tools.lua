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

local function walk(tbl, callback)
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      tbl[k] = callback(k, v) or tbl[k]
      walk(v, callback)
    else
      tbl[k] = callback(k, v) or tbl[k]
    end
  end
end

local function expect(x, T, error_message)
  assert(x == T, error_message)
end

local function builder(tbl)
  local res = {}
  for k, v in pairs(tbl) do
    res[k .. "_"] = function(self, value)
      self[k] = value
      return self
    end
    res[k] = v
  end
  return setmetatable(res, getmetatable(tbl))
end

return {
  ext = ext,
  expect = expect,
  walk = walk,
  builder = builder,
}

