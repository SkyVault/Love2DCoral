local vertex_format = {
  {"VertexPosition", "float", 3},
  --{"VertexTexCoord", "float", 2},
  --{"VertexNormal", "float", 3},
  --{"VertexColor", "byte", 4},
}

local vertex_shader_3d = [[
uniform mat4 projection; uniform mat4 view; uniform mat4 model;

attribute vec3 VertexNormal;

varying vec4 world_pos; varying vec4 view_pos; 
varying vec3 vertex_normal; varying vec4 vertex_color;
varying vec4 screen_pos; 

vec4 position(mat4 transform_projection, vec4 vertex_pos) {
  world_pos = model * vertex_pos;
  view_pos = view * world_pos;
  screen_pos = projection * view_pos;

  vertex_normal = VertexNormal;

  return screen_pos;
}
]]

return function(love, enum, sys, tools)
  local pics = {}
  local shader_3d = nil
  local plane_mesh = nil

  local scale = v3(1, 1, 1)
  local rot = 0

  local model_transform = {
    translation = v3(0, 0, 0),
    rotation = v3(0, 0, 0),
    scale = v3(1, 1, 1),
  }

  local kinds = enum {
    "rectangle",
    "line_rectangle",
    "circle",
    "line_circle",
  }

  local function plane(s, x, y, z)
    x, y, z = x or 0, y or 0, z or 0
    return {
      { x + -s, y + -s, z },
      { x + -s, y +  s, z },
      { x +  s, y +  s, z },
      { x + -s, y + -s, z },

      { x + -s, y + -s, z },
      { x +  s, y +  s, z },
      { x +  s, y + -s, z },
      { x + -s, y + -s, z },
    }
  end

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

  local mesh = {
    verts = {
      plane = plane,
    },
  }

  local function load()
    love.graphics.setDepthMode("lequal", true)

    shader_3d = love.graphics.newShader(vertex_shader_3d)

    mesh.plane = love.graphics.newMesh(
      vertex_format,
      mesh.verts.plane(1),
      "fan"
    )
  end

  local function final_draw()
    model_transform.rotation.y = rot

    local model_matrix = m4_transform(
      model_transform.translation,
      model_transform.rotation,
      model_transform.scale
    )

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

    love.graphics.setShader(shader_3d)
    shader_3d:send("model", model_matrix.m)

    local cam_pos = v3(0, 0, 2)
    local target = v3(0, 0, 0) -- cam_pos + v3(0, 0, 1)

    shader_3d:send("view", m4_view(cam_pos, target, v3(0, 1, 0)).m)

    local aspect = love.graphics.getWidth() / love.graphics.getHeight()

    shader_3d:send("projection", m4_projection(45.0, 0.001, 100.0, aspect).m)
    love.graphics.draw(mesh.plane)
    love.graphics.setShader()

    pics = {}
  end

  sys.on_load(load)

  sys.on_draw(final_draw, -1)
  sys.on_update(function(dt)
    rot = rot + dt
  end)

  return {
    kinds = kinds,
    draw = draw,
    pic = pic,
    rect = rect,
    line_rect = line_rect,
    circle = circle,
    line_circle = line_circle,

    mesh = mesh,
  }
end
