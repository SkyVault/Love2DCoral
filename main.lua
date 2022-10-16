local Coral = require("coral")(nil, love)
local component = Coral.actors.component

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

  Coral.timer(1, function()
    print("ONE")
    Coral.timer(1, function()
      print("TWO")
      Coral.timer(1, function()
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
  Coral.art.plane(
    v3(-1, -1, 0),
    v3(0, 0, 0),
    v3(0.01, 0.01, 0.01)
  ):color_(Red)

  Coral.art.plane(
    v3( 1, -1, 0),
    v3(0, 0, 0),
    v3(0.01, 0.01, 0.01)
  ):color_(Red)

  Coral.art.plane(
    v3( 1,  1, 0),
    v3(0, 0, 0),
    v3(0.01, 0.01, 0.01)
  ):color_(Red)

  Coral.art.plane(
    v3(-1,  1, 0),
    v3(0, 0, 0),
    v3(0.01, 0.01, 0.01)
  ):color_(Red)

  for i = 0, 2000 do
    local x = (-0.5 + math.random()) * 2
    local y = (-0.5 + math.random()) * 2
    Coral.art.plane(
      v3(x, -y, 0),
      v3(0, 0, 0),
      v3(0.01, 0.01, 0.01)
    ):color_(Yellow)
  end

  Coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    --Coral.art.draw(drawable.pic, spatial.x, spatial.y, spatial.w, spatial.h)

    Coral.art.rect(200, 200, 32, 32):color_(Tan)
  end)
end)

Coral.sys.on_draw(function()
  love.graphics.setColor(Green)
  love.graphics.print(_dt == 0 and 0 or 1/_dt, 10, 10)
  love.graphics.setColor(White)
end, -2)
