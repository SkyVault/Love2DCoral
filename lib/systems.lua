local loads = {}
local updates = {}
local draws = {}
local ui_draws = {}
local keypresses = {}
local keyreleases = {}

local function cmp(a, b)
  return a.priority < b.priority
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

local function on_ui_draw(fn, priority)
  table.insert(ui_draws, { fn = fn, priority = priority or 0 })
  table.sort(ui_draws, cmp)
end

local function on_keypressed(fn)
  table.insert(keypresses, fn)
end

local function on_keyreleased(fn)
  table.insert(keyreleases, fn)
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
  for i = 1, #ui_draws do
    ui_draws[i].fn()
  end
end

local function keypressed(k)
  for i = 1, #keypresses do
    keypresses[i](k)
  end
end

local function keyreleased(k)
  for i = 1, #keyreleases do
    keyreleases[i](k)
  end
end

return {
  on_load = on_load,
  on_update = on_update,
  on_draw = on_draw,
  on_ui_draw = on_ui_draw,
  on_keypressed = on_keypressed,
  on_keyreleased = on_keyreleased,

  internal = {
    load = load,
    update = update,
    draw = draw,
    keypressed = keypressed,
    keyreleased = keyreleased,
  },

  reload = function()
    load()
  end
}
