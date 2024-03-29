local coral = require("coral")(love)
local actors = coral.actors
local component = actors.component
local art, timer, clock, ui, vault = coral.art, coral.timer, coral.clock, coral.ui, coral.vault

local a_random_table = vault.table {
  hello = "world",
  [420] = { 1, 2, 3, { four = true } },
  pos = v2(45, 3.14159)
}

print(coral.vault.write(a_random_table))

--print(v2(1, 1), v2(12, 32) + v2(23, 4))

local rot = 0
local _dt = 0

local Spatial = component("Spatial") {
  x = 0, y = 0, w = 100, h = 100,
}

local Drawable = component("Drawable") {
  pic = coral.art.pic(coral.art.kinds.rectangle, 10, 10, 100, 100),
}

local panel = vault.table {
  x = 0,
}

local texture = nil

coral.sys.load(function()
  --love.profiler = require("lib.profile")
  --love.profiler.start()

  --for i = 1, 1000 do
    --local t = v3(math.random(), math.random(), math.random())
    --local r = v3(math.random(), math.random(), math.random())
    --local s = v3(math.random(), math.random(), math.random())
    --m4_transform(t, r, s)
  --end

  --love.report = love.profiler.report(20)
  --love.profiler.reset()
  --love.profiler.stop()

  love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
    resizable = true,
    depth = 16,
  })

  coral.assets.load_image("floor", "res/floor.png"):setFilter("nearest", "nearest")

  local do_tween = 0
  do_tween = function(dir)
    coral.tween.new(1, panel, { x = 200 * ((dir or 1) >= 1 and 1 or 0) })
      :start()
      :on_complete(function() do_tween((dir or 1) * -1) end)
  end
  do_tween()

  coral.actors.spawn(
    Spatial:new { x = 32, y = 200 },
    Drawable:new { }
  )

  timer(1, function()
    print("ONE")
    timer(1, function()
      print("TWO")
      timer(1, function()
        print("THREE")
      end)
    end)
  end)

  --coral.watch(panel, "tween")
end)

local t = false


print(coral)
coral.sys.update(function(dt)
  --rot = rot + dt
  --_dt = dt

  coral.watch(a_random_table, "1")
  coral.watch(a_random_table, "2")
  coral.watch(a_random_table, "3")
  coral.watch(a_random_table, "4")
  --coral.watch(dt, "dt")
  --coral.watch({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, "numbers")

  --ui:push_container(10, 10, love.graphics.getWidth()  - 20, love.graphics.getHeight() - 20)
  --for i = 1, 100 do
    --ui:button(tostring(i))
  --end
  --ui:pop_container()

  ui:push_container(panel.x, 300, 200, 200)
  ui:panel(200, 250)

  ui:push_theme { fg_color = Red }
  if ui:button("AButton") then
    print("Hello, World!")
  end
  ui:pop_theme()

  if ui:button("B") then
    print("Hello, World!")
  end

  for i = 1, 3 do
    ui:button("WRAP")
  end

  ui:newline()

  t = ui:toggle("Toggle Me", t)

  ui:divider()

  if ui:image_button(coral.assets.get_image("floor")) then
    print("HERE?")
  end

  ui:pop_container()
end)

coral.sys.draw(function()
  math.randomseed(1)

  art.plane(v3(0, 0, 0), v3(0, 0, 0), v3(1.0, 1.0, 1.0))
    :texture_(coral.assets.get_image("floor"))

  for i = 1, 100 do
    art.plane(
      v3((i % 10) * 2, math.floor(i / 10) * 2, 0),
      v3(clock.timer / i, clock.timer / i, clock.timer / i),
      v3(0.5, 0.5, 0.5)
    ):color_(coral.palette.next_bright_color())
  end

  --coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    --art.rect(200, 200, 32, 32):color_(Tan)
  --end)
end)

coral.sys.draw(function()
  love.graphics.setColor(Green)
  love.graphics.print(coral.clock.fps, 10, 10)
  love.graphics.setColor(White)

  love.graphics.print(love.report or "Please wait...")
end, 20)
