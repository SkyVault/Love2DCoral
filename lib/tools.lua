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

-- https://gist.github.com/tylerneylon/81333721109155b2d244#file-copy-lua-L77
local function copy(obj, seen)
	-- Handle non-tables and previously-seen tables.
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end

	-- New table; mark it as seen an copy recursively.
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in next, obj do res[copy(k, s)] = copy(v, s) end
	return setmetatable(res, getmetatable(obj))
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

local function map(callback, tbl)
  for i = 1, #tbl do
    tbl[i] = callback(tbl[i])
  end
  return tbl
end

local function filter(callback, tbl)
  local res = {}
  for i = 1, #tbl do
    if callback(tbl[i]) then
      table.insert(res, tbl[i])
    end
  end
  return res
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

local function set(...)
  local s = { vs = {} }
  local args = {...}
  for i = 1, #args do
    s.vs[args[i]] = args[i]
  end
  function s:has(item)
    return self.vs[item] ~= nil
  end
  function s:add(item)
    self.vs[item] = item
    return self
  end
  -- TODO:
  -- add
  -- sub
  -- union
  -- ect..
  return s
end

return {
  set = set,
  ext = ext,
  expect = expect,
  walk = walk,
  map = map,
  copy = copy,
  filter = filter,
  builder = builder,
}

