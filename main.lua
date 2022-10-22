local Coral = require("coral")(nil, love)
local actors = Coral.actors
local component = actors.component
local art, timer, clock, ui = Coral.art, Coral.timer, Coral.clock, Coral.ui

local rot = 0
local _dt = 0

local Spatial = component("Spatial") {
  x = 0, y = 0, w = 100, h = 100,
}

local Drawable = component("Drawable") {
  pic = Coral.art.pic(Coral.art.kinds.rectangle, 10, 10, 100, 100),
}

Coral.sys.on_load(function()
  local player = Coral.actors.actor(
    Spatial:new { x = 32, y = 200 },
    Drawable:new { }
  )

  Coral.actors.spawn(player)

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

Coral.sys.on_update(function(dt)
  rot = rot + dt
  _dt = dt

  ui:push_container(10, 10, love.graphics.getWidth()  - 20, love.graphics.getHeight() - 20)
  for i = 1, 100 do
    ui:button(tostring(i))
  end
  ui:pop_container()

  ui:push_container(100, 100, 200, 200)
  ui:panel(200, 200)
  if ui:button("hello, world") then
  end
  ui:pop_container()
end)

Coral.sys.on_draw(function()
  --math.randomseed(1)

  --art.plane(
    --v3(0, 0, 0),
    --v3(0, 0, 0),
    --v3(1.0, 1.0, 1.0)
  --):color_(Red)

  --for i = 1, 100 do
    --art.plane(
      --v3((i % 10) * 4, math.floor(i / 10) * 4, 0),
      --v3(clock.timer / i, clock.timer / i, clock.timer / i),
      --v3(0.5, 0.5, 0.5)
    --):color_(Coral.palette.next_bright_color())
  --end

  --Coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    --art.rect(200, 200, 32, 32):color_(Tan)
  --end)
end)

Coral.sys.on_draw(function()
  love.graphics.setColor(Green)
  love.graphics.print(Coral.clock.fps, 10, 10)
  love.graphics.setColor(White)
end, -2)
