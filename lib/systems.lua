local loads = {}
local updates = {}
local draws = {}
local ui_draws = {}
local keypresses = {}
local keyreleases = {}

local handled = {}

local function is_handled(fn)
  if handled[fn] then return true end
  handled[fn] = fn
  return false
end

local function cmp(a, b)
  return a.priority < b.priority
end

local function load(fn, priority)
  if is_handled(fn) then return end
  table.insert(loads, { fn = fn, priority = priority or 0 })
  table.sort(loads, cmp)
end

local function update(fn, priority)
  if is_handled(fn) then return end
  table.insert(updates, { fn = fn, priority = priority or 0 })
  table.sort(updates, cmp)
end

local function draw(fn, priority)
  if is_handled(fn) then return end
  table.insert(draws, { fn = fn, priority = priority or 0 })
  table.sort(draws, cmp)
end

local function ui_draw(fn, priority)
  if is_handled(fn) then return end
  table.insert(ui_draws, { fn = fn, priority = priority or 0 })
  table.sort(ui_draws, cmp)
end

local function on_keypressed(fn)
  if is_handled(fn) then return end
  table.insert(keypresses, fn)
end

local function on_keyreleased(fn)
  if is_handled(fn) then return end
  table.insert(keyreleases, fn)
end

local function _load()
  for i = 1, #loads do
    loads[i].fn()
  end
end

local function _update(dt)
  for i = 1, #updates do
    updates[i].fn(dt)
  end
end

local function _draw()
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
  load = load,
  update = update,
  draw = draw,
  ui_draw = ui_draw,
  keypressed = on_keypressed,
  keyreleased = on_keyreleased,

  internal = {
    load = _load,
    update = _update,
    draw = _draw,
    keypressed = keypressed,
    keyreleased = keyreleased,
  },

  reload = function()
    load()
  end
}
