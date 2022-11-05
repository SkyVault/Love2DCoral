return function(tools, vault)
  local set = tools.set
  local copy = tools.copy
  local map = tools.map
  local filter = tools.filter
  local ext = tools.ext

  local actors = {}
  local spawns = {}
  local actors_by_id = {}
  local views = {}
  local unpack = table.unpack

  local _id = 0

  -- Ev.defsignal("actor-killed")
  local function next_id()
    _id = _id + 1
    return love.data.encode("string", "hex", love.data.hash("md5", tostring(_id)))
  end

  local actor = vault.table("actor") {
      _components_ = {},
      _tags_ = set(),
      _should_destroy_ = false,
      _id_ = next_id(),

      id = function(self)
        return self._id_
      end,

      kill = function(self)
        self._should_destroy_ = true
        --Ev.emit("actor-killed", self)
      end,

      dead = function(self)
        return self._should_destroy_
      end,

      add = function(self, ...)
        for _, v in ipairs({ ... }) do
          self._components_[v["component:name"]] = copy(v)
        end
        return self
      end,

      add_tags = function(self, ...)
        local ts = { ... }
        for i = 1, #ts do
          self._tags_:add(ts[i])
        end
      end,

      has_tag = function(self, tag)
        return self._tags_:has(tag)
      end,

      has = function(self, ...)
        for _, v in ipairs({ ... }) do
          if self._components_[v["component:name"]] == nil then
            return false
          end
        end
        return true
      end,

      get = function(self, ...)
        local comps = { ... }
        if #comps == 1 then
          return self._components_[comps[1]["component:name"]]
        else
          return unpack(map(function(it) return self:get(it) end, comps))
        end
      end,
  }


  local function clear_killed(c)
    actors = filter(
    function(a)
      local cc = c and c(a)
      local res = not a:dead() and (cc or true)
      -- this is weird
      if not res then
        actors_by_id[a:id()] = nil
      end

      return res
    end,
    actors
    )
    views = {}
  end

  local function key(cs)
    table.sort(cs, function(a, b)
      return a["component:name"]:upper() > b["component:name"]:upper()
    end)
    local k = ""
    for i = 1, #cs do
      k = k .. cs[i]["component:name"]
    end
    return k
  end

  local function get_actor(id)
    return actors_by_id[id]
  end

  local function spawn(...)
    local ac = actor:new():add(...)
    table.insert(actors, ac)
    actors_by_id[ac:id()] = ac
    views = {}
  end

  local function view(...)
    local cs = { ... }
    local k = key(cs)
    local res = {}
    if views[k] then
      return views[k]
    else
      for i = 1, #actors do
        local actor = actors[i]
        for ci = 1, #cs do
          if not actor:has(cs[ci]) then
            goto continue
          end
        end

        table.insert(res, actor)

        ::continue::
      end
      views[k] = res
      return res
    end
  end

  local function each(cs, callback)
    local as = view(unpack(cs))
    for i = 1, #as do
      callback(as[i], unpack(map(function(c) return as[i]:get(c) end, cs)))
    end
  end

  local function first_match(...)
    return view(...)[1]
  end

  local function component(name)
    if type(name) == "table" then
      return vault.ext2(vault.base(name)) {

      }
    end

    return function(tbl)
      tbl = vault.base(tbl)


      if name then
        tbl["component:name"] = name
        vault.types[name] = tbl
      end

      return tbl
    end
  end

  return {
    actor = actor,
    component = component,
    view = view,
    spawn = spawn,
    each = each,
    get_actor = get_actor,
    first_match = first_match,
    clear_killed = clear_killed
  }
end
