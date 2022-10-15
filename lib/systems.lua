local loads = {}
local updates = {}
local draws = {}

local function cmp(a, b)
  return a.priority > b.priority
end

local function on_load(fn, priority)
  table.insert(loads, { fn = fn, priority = priority or 0 })
  table.sort(loads, cmp)
end

local function on_update(fn, priority)
  table.insert(updates, { fn = fn, priority = priority or 0 })
  table.sort(updates, cmp)
end

local function on_draw(fn, priority)
  table.insert(draws, { fn = fn, priority = priority or 0 })
  table.sort(draws, cmp)
end

local function load()
  for i = 1, #loads do
    loads[i].fn()
  end
end

local function update(dt)
  for i = 1, #updates do
    updates[i].fn(dt)
  end
end

local function draw()
  for i = 1, #draws do
    draws[i].fn()
  end
end

return {
  on_load = on_load,
  on_update = on_update,
  on_draw = on_draw,

  internal = {
    load = load,
    update = update,
    draw = draw,
  },

  reload = function()
    load()
  end
}
