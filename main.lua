local Coral = require("coral")(nil, love)
local component = Coral.actors.component

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
end)

Coral.sys.on_update(function()
end)

Coral.sys.on_draw(function()
  Coral.actors.each({ Spatial, Drawable }, function(_, spatial, drawable)
    Coral.art.draw(drawable.pic, spatial.x, spatial.y, spatial.w, spatial.h)
  end)
end)
