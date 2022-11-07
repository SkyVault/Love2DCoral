local fmt = string.format
local atan, cos, sin = math.atan, math.cos, math.sin

---@diagnostic disable-next-line: redefined-local
local vertex_format = {
  {"VertexPosition", "float", 3},
  {"VertexTexCoord", "float", 2},
  {"VertexNormal", "float", 3},
  --{"VertexColor", "byte", 4},
}

local vertex_shader_3d = [[
uniform mat4 projection; uniform mat4 view; uniform mat4 model;

attribute vec3 VertexNormal;

varying vec4 world_pos; varying vec4 view_pos; 
varying vec3 vertex_normal; varying vec4 vertex_color;
varying vec3 frag_pos; 

vec4 position(mat4 transform_projection, vec4 vertex_pos) {
  world_pos = model * vertex_pos;
  view_pos = view * world_pos;

  vec4 mvp = projection * view_pos;

  vec4 f = model * vertex_pos;
  frag_pos = f.xyz;

  vertex_normal = VertexNormal;

  return mvp;
}
]]

local fragment_shader_3d = [[
varying vec3 vertex_normal;
varying vec3 frag_pos;

vec3 light_pos = vec3(10, 4, 10);
vec3 ambient = vec3(0.2, 0.2, 0.2);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 texturecolor = Texel(tex, texture_coords);

    vec3 norm = normalize(vertex_normal);
    vec3 light_dir = normalize(light_pos - frag_pos);

    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = diff * vec3(1, 1, 1);

    return texturecolor * color * vec4(ambient + diffuse, 1.0);
}
]]

return function(love, enum, sys, tools, camera, pp, vault)
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

  local camera2ds = {}

  local function add_camera_2d(cam, make_active)
     table.insert(
       camera2ds,
       vault.ext(cam, { is_active = make_active or cam.is_active })
     )
  end

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
    "line",
    "image",
    "text",
    "paragraph",
    "plane",
    "crop",
  }

  local function plane_vertices(s, x, y, z)
    x, y, z = x or 0, y or 0, z or 0
    return {
      { x + -s, y + -s, z,  0, 1,  0, 1, 0 },
      { x + -s, y +  s, z,  0, 0,  0, 1, 0 },
      { x +  s, y +  s, z,  1, 0,  0, 1, 0 },
      { x + -s, y + -s, z,  0, 0,  0, 1, 0 },
      { x + -s, y + -s, z,  0, 1,  0, 1, 0 },
      { x +  s, y +  s, z,  1, 0,  0, 1, 0 },
      { x +  s, y + -s, z,  1, 1,  0, 1, 0 },
      { x + -s, y + -s, z,  0, 1,  0, 1, 0 },
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
      corner_radius = 0,
    }
    add_pic(res)
    return res
  end

  local function tkey(t, r, s)
    return fmt("%x%x%x%x%x%x%x%f%f",t.x,t.y,t.z,r.x,r.y,r.z,s.x,s.y,s.z)
  end

  local _transform_cache = {}

  local function pic3d(kind, translation, rotation, scle)
    local t = { t = translation, r = rotation, s = scle }

    local res = tools.builder {
      kind = kind,
      transform = t,
      position = translation,
      color = {1, 1, 1, 1},
      texture = 0,
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

  local function line(x1, y1, x2, y2)
    return pic(kinds.line, x1, y1, x2, y2)
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

  local function image(img, x, y)
    local i = pic(kinds.image, x, y, img:getWidth(), img:getHeight())
    i.image = img
    return i
  end

  local function text(txt, fnt, x, y)
    local w, h = fnt:getWidth(txt), fnt:getHeight()
    local p = pic(kinds.text, x, y, w, h)
    p.text = txt
    p.font = fnt
    return p
  end

  local function paragraph(txt, fnt, x, y, limit, align)
    local w, h = fnt:getWidth(txt), fnt:getHeight()
    local p = pic(kinds.paragraph, x, y, w, h)
    p.text = txt
    p.font = fnt
    p.limit = limit
    p.aligh = align
    return p
  end

  local function crop(x, y, w, h, fn)
    local p = pic(kinds.crop, x, y, w, h)
    p.callback = fn
    return p
  end

  local function plane(translation, rotation, scle)
    return pic3d(kinds.plane, translation, rotation, scle)
  end

  local function build_mesh(vertices)
    local m = love.graphics.newMesh(
      vertex_format,
      vertices,
      "fan"
    )
    return m
  end

  local mesh = {
    verts = {
      plane = plane_vertices,
    },
  }

  local function resize(w, h)
    camera.aspect = love.graphics.getWidth() / love.graphics.getHeight()
  end

  local function load()
    love.graphics.setDepthMode("lequal", true)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.window.setMode(w, h, {
      depth = 16
    })

    shader_3d = love.graphics.newShader(fragment_shader_3d, vertex_shader_3d)

    mesh.plane = build_mesh(mesh.verts.plane(1))
  end

  local function active_camera_2d()
    local active_camera = nil
    for i = 1, #camera2ds do
      if camera2ds[i].is_active then
        active_camera = camera2ds[i]
        break
      end
    end
    return active_camera
  end

  local function to_world_coords(x, y)
    local cam = active_camera_2d()
    if not cam then return x, y end
    local hw, hh = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    --local c, s = cos(cam.rotation), sin(cam.rotation)
    --local xx, yy = (x - hw) / cam.scale, (y - hh) / cam.scale
    --xx, yy = c*xx - s*yy, s*xx + c*yy
    return x - cam.position.x - hw, y - cam.position.y - hh
  end

  local function to_camera_coords(x, y)
    local cam = active_camera_2d()
    if not cam then return x, y end
    local hw, hh = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    local c, s = cos(cam.rotation), sin(cam.rotation)
    local xx, yy = x - cam.position.x, y - cam.position.y
    xx, yy = c*xx - s*yy, s*xx + c*yy
    return xx * cam.scale + hw, yy * cam.scale + hh
  end


  local x = 0

  local function draw_pictures(pcs)
    local cam2d = active_camera_2d()

    for ctx, ps in pairs(pcs) do
      for i = 1, #ps do
        local p = ps[i]
        kinds.case(p.kind) {
          [kinds.crop] = function()
            local _pics = pics
            pics = {}
            if p.callback then p.callback() end

            if cam2d then cam2d:stop() end
            love.graphics.setScissor(p.x, p.y, p.w, p.h)
            draw_pictures(pics)
            love.graphics.setScissor()
            if cam2d then cam2d:start() end

            pics = _pics
          end,

          [kinds.line] = function()
            local x1, y1, x2, y2 = p.x, p.y, p.w, p.h

            love.graphics.setColor(p.color)
            love.graphics.line(x1, y1, x2, y2)
          end,

          [kinds.rectangle] = function()
            love.graphics.setColor(p.color)
            love.graphics.rectangle("fill", p.x, p.y, p.w, p.h, p.corner_radius, p.corner_radius, p.corner_radius > 0 and p.corner_radius or nil)
          end,

          [kinds.line_rectangle] = function()
            love.graphics.setColor(p.color)
            love.graphics.rectangle("line", p.x, p.y, p.w, p.h, p.corner_radius, p.corner_radius, p.corner_radius > 0 and p.corner_radius or nil)
          end,

          [kinds.circle] = function()
            love.graphics.setColor(p.color)
            love.graphics.circle("fill", p.x, p.y, p.w)
          end,

          [kinds.line_circle] = function()
            love.graphics.setColor(p.color)
            love.graphics.circle("line", p.x, p.y, p.w)
          end,

          [kinds.image] = function()
            love.graphics.setColor(p.color)
            love.graphics.draw(p.image, p.x, p.y)
          end,

          [kinds.text] = function()
            love.graphics.setColor(p.color)
            love.graphics.setFont(p.font)
            love.graphics.print(p.text, p.x, p.y, p.rotation)
          end,

          [kinds.paragraph] = function()
            love.graphics.setColor(p.color)
            love.graphics.setFont(p.font)
            love.graphics.printf(p.text, p.x, p.y, p.limit, p.align, p.rotation)
          end,
        }
      end
    end
  end

  local function final_draw()
    x = x + 0.01

    table.sort(pics, function(a, b)
      return a.layer < b.layer
    end)

    local cam2d = active_camera_2d()

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
          local t = m4_transform(p.transform.t, p.transform.r, p.transform.s)
          shader_3d:send("model", t.m)
          -- we should group by texture for performance
          if p.texture ~= 0 then
            mesh.plane:setTexture(p.texture)
          end
          love.graphics.draw(mesh.plane)
        end,
      }
    end

    love.graphics.setShader()
 
    if cam2d then cam2d:start() end

    draw_pictures(pics)

    love.graphics.setColor(init_color)
    if cam2d then cam2d:stop() end

    pics = {}
    pics_3d = {}
  end

  sys.load(load)
  sys.draw(final_draw, -1)
  sys.update(function(dt) end)

  return {
    kinds = kinds,
    resize = resize,
    set_context = set_context,
    push_context = push_context,
    pop_context = pop_context,
    with_context = with_context,

    build_mesh = build_mesh,

    add_camera_2d = add_camera_2d,

    to_world_coords = to_world_coords,
    to_camera_coords = to_camera_coords,

    draw = draw,
    pic = pic,
    rect = rect,
    line_rect = line_rect,
    circle = circle,
    line_circle = line_circle,
    line = line,
    text = text,
    paragraph = paragraph,
    crop = crop,
    image = image,
    plane = plane,

    mesh = mesh,
  }
end
