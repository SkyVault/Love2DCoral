local coral = require("coral")(nil, love)
local actors = coral.actors
local component = actors.component
local art, timer, clock, ui = coral.art, coral.timer, coral.clock, coral.ui

print(v2(1, 1), v2(12, 32) + v2(23, 4))

local rot = 0
local _dt = 0

local Spatial = component("Spatial") {
  x = 0, y = 0, w = 100, h = 100,
}

local Drawable = component("Drawable") {
  pic = coral.art.pic(coral.art.kinds.rectangle, 10, 10, 100, 100),
}

local panel = { x = 0 }

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

  coral.tween.new(1, panel, { x = 200 }):start():on_complete_(function()
    coral.tween.new(1, panel, { x = 0 }):start():on_complete_(function()
    end)
  end)

  local a_random_table = coral.vault.table {
    hello = "world",
    [420] = { 1, 2, 3, { four = true } },
  }

  print(a_random_table)

  local player = coral.actors.spawn(
    Spatial:new { x = 32, y = 200 },
    Drawable:new { }
  )

  coral.actors.spawn(player)

  timer(1, function()
    print("ONE")
    timer(1, function()
      print("TWO")
      timer(1, function()
        print("THREE")
      end)
    end)
  end)
end)

local t = false

coral.sys.update(function(dt)
  --rot = rot + dt
  --_dt = dt

  ui:push_container(10, 10, love.graphics.getWidth()  - 20, love.graphics.getHeight() - 20)
  for i = 1, 100 do
    ui:button(tostring(i))
  end
  ui:pop_container()

  ui:push_container(panel.x, 100, 200, 200)
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

  ui:label("Hello")
  ui:title("Hello World!")

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

  coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    art.rect(200, 200, 32, 32):color_(Tan)
  end)
end)

coral.sys.draw(function()
  love.graphics.setColor(Green)
  love.graphics.print(coral.clock.fps, 10, 10)
  love.graphics.setColor(White)

  love.graphics.print(love.report or "Please wait...")
end, 20)
