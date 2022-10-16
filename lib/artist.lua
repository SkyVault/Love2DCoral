return function(love, enum, sys, tools)
  local pics = {}

  local kinds = enum {
    "rectangle",
    "line_rectangle",
    "circle",
    "line_circle",
  }

  local function pic(kind, x, y, w, h)
    local res = tools.builder {
      kind = kind,
      x = x, y = y, w = w, h = h,
      rotation = 0,
      color = {1, 1, 1, 1},
      layer = 0
    }
    table.insert(pics, res)
    return res
  end

  local function draw(p, x, y, w, h)
    p.x = x or p.x
    p.y = y or p.y
    p.w = w or p.w
    p.h = h or p.h
    table.insert(pics, p)
  end

  local function rect(x, y, w, h)
    return pic(kinds.rectangle, x, y, w, h)
  end

  local function line_rect(x, y, w, h)
    return pic(kinds.line_rectangle, x, y, w, h)
  end

  local function circle(x, y, r)
    return pic(kinds.circle, x, y, r * 2, r * 2)
  end

  local function line_circle(x, y, r)
    return pic(kinds.line_circle, x, y, r * 2, r * 2)
  end

  local function final_draw()
    table.sort(pics, function(a, b)
      return a.layer < b.layer
    end)

    local init_color = { love.graphics.getColor() }

    for i = 1, #pics do
      local p = pics[i]

      kinds.match(p.kind) {
        [kinds.rectangle] = function()
          love.graphics.setColor(p.color)
          love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
        end,

        [kinds.line_rectangle] = function()
          love.graphics.setColor(p.color)
          love.graphics.rectangle("line", p.x, p.y, p.w, p.h)
        end,

        [kinds.circle] = function()
          love.graphics.setColor(p.color)
          love.graphics.circle("fill", p.x, p.y, p.w)
        end,

        [kinds.line_circle] = function()
          love.graphics.setColor(p.color)
          love.graphics.circle("line", p.x, p.y, p.w)
        end,
      }
    end

    love.graphics.setColor(init_color)
    pics = {}
  end

  sys.on_load(function()
    love.graphics.setDepthMode("lequal", true)
  end)

  sys.on_draw(final_draw, -1)

  return {
    kinds = kinds,
    draw = draw,
    pic = pic,
    rect = rect,
    line_rect = line_rect,
    circle = circle,
    line_circle = line_circle,
  }
end
