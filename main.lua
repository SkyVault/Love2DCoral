local Coral = require("coral")(nil, love)

local ds = {
  { Coral.art.rect,         Coral.palette.next_bright_color(), 1 },
  { Coral.art.line_rect,    Coral.palette.next_bright_color(), 1 },
  { Coral.art.circle,       Coral.palette.next_bright_color(), 1 },
  { Coral.art.line_circle,  Coral.palette.next_bright_color(), 1 },
  { Coral.art.rect,         Coral.palette.next_bright_color(), 1 },
  { Coral.art.line_rect,    Coral.palette.next_bright_color(), 1 },
  { Coral.art.circle,       Coral.palette.next_bright_color(), 1 },
  { Coral.art.line_circle,  Coral.palette.next_bright_color(), 1 },
}

Coral.sys.on_draw(function()
  for i = 1, #ds do
    ds[i][1](i * 20, i * 20, 10, 10):color_(ds[i][2]):layer_(ds[i][3])
  end
end)

function love.load()
end

function love.update(_)
end

function love.draw()
end
