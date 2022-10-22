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

return function(love, enum, sys, tools, camera, pp)
  local contexts = enum {
    "normal",
    "ui"
  }

  local pics_3d = {}
  local pics = {}

  local shader_3d = nil

  local scale = v3(1, 1, 1)

  local cam_pos = v3(0, 0, 2)
  local target = v3(0, 0, 0)
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  local _context_stack = {}
  local context = contexts.normal

  local function set_context(to)
    context = to
  end

  local function push_context(ctx)
    table.insert(_context_stack, ctx)
  end

  local function pop_context()
    table.remove(_context_stack, #_context_stack)
  end

  local function with_context(ctx, callback)
    push_context(ctx)
    callback()
    pop_context(ctx)
  end

  local function add_pic(pic)
    pics[context] = pics[context] or {}
    table.insert(pics[context], pic)
  end

  local kinds = enum {
    "rectangle",
    "line_rectangle",
    "circle",
    "line_circle",
    "text",
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
      layer = 0,
      context = context,
    }
    add_pic(res)
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
      position = translation,
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

  local function text(txt, fnt, x, y)
    local w, h = fnt:getWidth(txt), fnt:getHeight()
    local p = pic(kinds.text, x, y, w, h)
    p.text = txt
    p.font = fnt
    return p
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
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.window.setMode(w, h, {
      depth = 16
    })

    shader_3d = love.graphics.newShader(vertex_shader_3d)

    mesh.plane = love.graphics.newMesh(
      vertex_format,
      mesh.verts.plane(1),
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

    -- BSP would be pretty handy

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

    for ctx, ps in pairs(pics) do
      for i = 1, #ps do
        local p = ps[i]
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

          [kinds.text] = function()
            love.graphics.setColor(p.color)
            love.graphics.setFont(p.font)
            love.graphics.print(p.text, p.x, p.y, p.rotation)
          end,
        }
      end
    end

    love.graphics.setColor(init_color)

    pics = {}
    pics_3d = {}
  end

  sys.on_load(load)
  sys.on_draw(final_draw, -1)

  sys.on_update(function(dt)
    if love.keyboard.isDown("e")  then
      camera.yaw = camera.yaw - dt * 5
    end

    if love.keyboard.isDown("q")  then
      camera.yaw = camera.yaw + dt * 5
    end

    local mx, my = 0, 0

    if love.keyboard.isDown("s") then my = my - 1 end
    if love.keyboard.isDown("w") then my = my + 1 end
    if love.keyboard.isDown("a") then mx = mx - 1 end
    if love.keyboard.isDown("d") then mx = mx + 1 end

    if mx ~= 0 or my ~= 0 then

      local d = camera.yaw +
        (my < 0 and math.pi or 0) +
        (mx < 0 and math.pi/2 or
        (mx > 0 and -math.pi/2 or 0))

      local dx, dy = cos(d) * dt, sin(d) * dt

      camera.position.x = camera.position.x + dx * 5
      camera.position.y = camera.position.y + dy * 5
    end

    if love.keyboard.isDown("-") then
      camera.position.z = camera.position.z + dt * 5
    end

    if love.keyboard.isDown("=") then
      camera.position.z = camera.position.z - dt * 5
    end
  end)

  return {
    kinds = kinds,
    set_context = set_context,
    push_context = push_context,
    pop_context = pop_context,
    with_context = with_context,

    draw = draw,
    pic = pic,
    rect = rect,
    line_rect = line_rect,
    circle = circle,
    line_circle = line_circle,
    text = text,
    plane = plane,

    mesh = mesh,
  }
end
