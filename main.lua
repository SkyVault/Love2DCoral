local Coral = require("coral")(nil, love)
local component = Coral.actors.component
local art = Coral.art
local timer = Coral.timer

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
end)

Coral.sys.on_draw(function()
  math.randomseed(1)

  art.plane(
    v3(0, 0, 0),
    v3(0, 0, 0),
    v3(1.0, 1.0, 1.0)
  ):color_(Red)

  art.plane(
    v3(5, 5, 0),
    v3(Coral.clock.timer, Coral.clock.timer, Coral.clock.timer),
    v3(1.0, 1.0, 1.0)
  ):color_(Red)

  Coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    art.rect(200, 200, 32, 32):color_(Tan)
  end)
end)

Coral.sys.on_draw(function()
  love.graphics.setColor(Green)
  love.graphics.print(Coral.clock.fps, 10, 10)
  love.graphics.setColor(White)
end, -2)
