local fmt = string.format
local atan, cos, sin = math.atan, math.cos, math.sin

---@diagnostic disable-next-line: redefined-local
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

return function(love, enum, sys, tools, camera)
  local pics_3d = {}
  local pics = {}

  local shader_3d = nil

  local scale = v3(1, 1, 1)

  local cam_pos = v3(0, 0, 2)
  local target = v3(0, 0, 0)
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  local kinds = enum {
    "rectangle",
    "line_rectangle",
    "circle",
    "line_circle",
    "plane",
  }

  local function plane_vertices(s, x, y, z)
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

  local function tkey(t, r, s)
    return fmt("%f%f%f%f%f%f%f%f%f",t.x,t.y,t.z,r.x,r.y,r.z,s.x,s.y,s.z)
  end

  local transform_cache = {}

  local function pic3d(kind, translation, rotation, scle)
    local t = m4_transform(translation, rotation, scle)

    local res = tools.builder {
      kind = kind,
      transform = t,
      color = {1, 1, 1, 1},
    }

    table.insert(pics_3d, res)
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

  local function plane(translation, rotation, scle)
    return pic3d(kinds.plane, translation, rotation, scle)
  end

  local mesh = {
    verts = {
      plane = plane_vertices,
    },
  }

  local function load()
    love.graphics.setDepthMode("lequal", true)

    shader_3d = love.graphics.newShader(vertex_shader_3d)

    mesh.plane = love.graphics.newMesh(
      vertex_format,
      mesh.verts.plane(2),
      "fan"
    )
  end

  local x = 0

  local function final_draw()
    x = x + 0.01
    table.sort(pics, function(a, b)
      return a.layer < b.layer
    end)

    local init_color = { love.graphics.getColor() }

    love.graphics.setShader(shader_3d)

    camera:look_in_direction(camera.position, camera.yaw, camera.pitch)

    shader_3d:send("view", camera.view.m)
    shader_3d:send("projection", camera.projection.m)

    for i = 1, #pics_3d do
      local p = pics_3d[i]

      kinds.case(p.kind) {
        [kinds.plane] = function()
          love.graphics.setColor(p.color)

          local t = p.transform
          shader_3d:send("model", t.m)

          love.graphics.draw(mesh.plane)
        end,
      }
    end

    love.graphics.setShader()

    for i = 1, #pics do
      local p = pics[i]

      kinds.case(p.kind) {
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
    pics_3d = {}
  end

  sys.on_load(load)
  sys.on_draw(final_draw, -1)

  sys.on_update(function(dt)
    if love.keyboard.isDown("e")  then
      camera.yaw = camera.yaw - dt
    end

    if love.keyboard.isDown("q")  then
      camera.yaw = camera.yaw + dt
    end

    local mx, my = 0, 0

    if love.keyboard.isDown("s") then my = my - 1 end
    if love.keyboard.isDown("w") then my = my + 1 end
    if love.keyboard.isDown("a") then mx = mx - 1 end
    if love.keyboard.isDown("d") then mx = mx + 1 end

    if mx ~= 0 or my ~= 0 then
      local a = atan(my, mx)
      local d = camera.yaw - math.pi/4
      local dx, dy = cos(d + a) * dt, sin(d + a) * dt
      camera.position.x = camera.position.x + dx
      camera.position.y = camera.position.y + dy
    end

    if love.keyboard.isDown("-") then
      camera.position.z = camera.position.z + dt
    end

    if love.keyboard.isDown("=") then
      camera.position.z = camera.position.z - dt
    end
  end)

  return {
    kinds = kinds,
    draw = draw,
    pic = pic,
    rect = rect,
    line_rect = line_rect,
    circle = circle,
    line_circle = line_circle,
    plane = plane,

    mesh = mesh,
  }
end
