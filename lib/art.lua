require "lib.neum"
require "palette"

local floor = math.floor
local mv2 = math.v2
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

CellSides = {
    N = 0,
    E = 1,
    S = 2,
    W = 3,
    T = 4,
    B = 5
}

local Art = {
    canvas = nil,
    image = nil,
    depth = {},

    pics = {},

    textures = {},
    texture_data = {},

    camera = {
        pos = {
            x = 2,
            y = 2
        },
        heading = 0,
        fov = math.rad(60) -- math.pi / 3.3333
    },

    is_location_solid = function(self, x, y)
        return false
    end,

    select_scenery_pixel = function(self, x, y, cell_side, plane_sample, plane_z)
        return { 0, 0, 0, 1 }
    end
}

local _layer = 0

local function _next_layer()
    _layer = _layer + 0.0001
    return _layer
end

local function map_black(x, y, r, g, b, a)
    return 0.0, 0.0, 0.0, 0.0
end

function Art:rect(x, y, w, h, color, layer)
    table.insert(self.pics, {
        kind = "rect",
        x = x,
        y = y,
        w = w,
        h = h,
        color = color or White,
        layer = layer or _next_layer()
    })
end

function Art:poly(vertices, color, layer)
    table.insert(self.pics, {
        kind = "poly",
        vertices = vertices,
        color = color or White,
        layer = layer or _next_layer()
    })
end

function Art:circle(x, y, r, color, layer)
    table.insert(self.pics, {
        kind = "circle",
        x = x,
        y = y,
        radius = r,
        color = color or White,
        layer = layer or _next_layer()
    })
end

function Art:line_rect(x, y, w, h, color, layer)
    table.insert(self.pics, {
        kind = "line_rect",
        x = x,
        y = y,
        w = w,
        h = h,
        color = color,
        layer = layer or _next_layer()
    })
end

function Art:print(text, font, x, y, color, layer)
    table.insert(self.pics, {
        kind = "print",
        font = font,
        x = x,
        y = y,
        text = text,
        color = color,
        layer = layer or _next_layer()
    })
end

function Art:paint(drawable, x, y, r, sx, sy, color, layer)
    table.insert(self.pics, {
        kind = "paint",
        drawable = drawable,
        x = x,
        y = y,
        w = drawable:getWidth(),
        h = drawable:getHeight(),
        r = r or 0,
        sx = sx or 1,
        sy = sy or 1,
        color = color or White,
        layer = layer or _next_layer(),
    })
end

function Art:typography(text, font, x, y, color, layer)
    table.insert(self.pics, {
        kind = "typography",
        font = font,
        text = text,
        x = x,
        y = y,
        color = color,
        layer = layer or _next_layer()
    })
end

function Art:get_window_canvas_scale_ratio()
    local w, h = love.graphics.getDimensions()
    return w / self.canvas:getWidth(), h / self.canvas:getHeight()
end

function Art:load()
    self.canvas = love.image.newImageData(128 * (16 / 9), 128, "rgba8")
    self.image = love.graphics.newImage(self.canvas)
    self.image:setFilter("nearest", "nearest")

    for y = 1, self.canvas:getHeight() do
        for x = 1, self.canvas:getWidth() do
            self.depth[x + y * self.canvas:getWidth()] = 0.0
        end
    end
end

function Art:set_camera(pos, heading)
    self.camera.pos = pos
    self.camera.heading = heading
end

function Art:depth_draw(x, y, z, color)
    if z or 0 < (self.depth[(x + y * self.canvas:getWidth()) + 1] or 0) then
        self.canvas:setPixel(x, y, table.unpack(color))
        self.depth[(x + y * self.canvas:getWidth()) + 1] = z
    end
end

function Art:clear_canvas(r, g, b)
    self.canvas:mapPixel(function(x, y, _, _, _, _)
        return r, g, b, 1
    end, 0, 0, self.canvas:getWidth(), self.canvas:getHeight())
    for i = 1, self.canvas:getWidth() * self.canvas:getHeight() do
        self.depth[i] = 9999.0
    end
end

local function magnitude(v2)
    return sqrt((v2.x * v2.x) + (v2.y * v2.y))
end

function Perp(v2)
    return {
        x = -v2.y,
        y = v2.x
    }
end

function Art:cast_ray(dir)
    local origin = mv2(self.camera.pos.x, self.camera.pos.y)
    local delta = mv2(sqrt(1 + (dir.y / dir.x) * (dir.y / dir.x)),
        sqrt(1 + (dir.x / dir.y) * (dir.x / dir.y)))

    local check = mv2(floor(origin.x), floor(origin.y))

    local side_dist = mv2()
    local step_dist = mv2()

    if dir.x < 0 then
        step_dist.x = -1
        side_dist.x = (origin.x - check.x) * delta.x
    else
        step_dist.x = 1
        side_dist.x = (check.x + 1.0 - origin.x) * delta.x
    end

    if dir.y < 0 then
        step_dist.y = -1
        side_dist.y = (origin.y - check.y) * delta.y
    else
        step_dist.y = 1
        side_dist.y = (check.y + 1.0 - origin.y) * delta.y
    end

    local inter = mv2()

    local max_dist = 35.0
    local dist = 0.0
    local tile_found = false

    local hit = nil

    while not tile_found and dist < max_dist do
        if side_dist.x < side_dist.y then
            side_dist.x = side_dist.x + delta.x
            check.x = check.x + step_dist.x
        else
            side_dist.y = side_dist.y + delta.y
            check.y = check.y + step_dist.y
        end

        local ray_dist = mv2(check.x - origin.x, check.y - origin.y)

        dist = magnitude(ray_dist)

        if Art:is_location_solid(check.x, check.y) then
            hit = {
                tile_pos = {
                    x = check.x,
                    y = check.y
                },
                hit_pos = {
                    x = 0,
                    y = 0
                },
                size = 0,
                sample_x = 0
            }
            tile_found = true

            local m = dir.y / dir.x

            if origin.y <= check.y then
                if origin.x <= check.x then
                    hit.size = CellSides.W
                    inter.y = m * (check.x - origin.x) + origin.y
                    inter.x = check.x
                    hit.sample_x = inter.y - floor(inter.y)
                elseif origin.x >= check.x + 1 then
                    hit.side = CellSides.E
                    inter.y = m * ((check.x + 1) - origin.x) + origin.y
                    inter.x = check.x + 1
                    hit.sample_x = inter.y - floor(inter.y)
                else
                    hit.side = CellSides.N
                    inter.y = check.y
                    inter.x = (check.y - origin.y) / m + origin.x
                    hit.sample_x = inter.x - floor(inter.x)
                end

                if inter.y < check.y then
                    hit.size = CellSides.N
                    inter.y = check.y
                    inter.x = (check.y - origin.y) / m + origin.x
                    hit.sample_x = inter.x - floor(inter.x)
                end
            elseif origin.y >= check.y + 1 then
                if origin.x <= check.x then
                    hit.side = CellSides.W
                    inter.y = m * (check.x - origin.x) + origin.y
                    inter.x = check.x
                    hit.sample_x = inter.y - floor(inter.y)
                elseif origin.x >= check.x + 1 then
                    hit.size = CellSides.E
                    inter.y = m * ((check.x + 1) - origin.x) + origin.y
                    inter.x = check.x + 1
                    hit.sample_x = inter.y - floor(inter.y)
                else
                    hit.size = CellSides.S
                    inter.y = check.y + 1
                    inter.x = ((check.y + 1) - origin.y) / m + origin.x
                    hit.sample_x = inter.x - floor(inter.x)
                end

                if inter.y > check.y + 1 then
                    hit.side = CellSides.S
                    inter.y = check.y + 1
                    inter.x = ((check.y + 1) - origin.y) / m + origin.x
                    hit.sample_x = inter.x - floor(inter.x)
                end
            else
                if origin.x <= check.x then
                    hit.size = CellSides.W
                    inter.y = m * (check.x - origin.x) + origin.y
                    inter.x = check.x
                    hit.sample_x = inter.y - floor(inter.y)
                elseif origin.x >= check.x + 1 then
                    hit.size = CellSides.E
                    inter.y = m * ((check.x + 1) - origin.x) + origin.y
                    inter.x = check.x + 1
                    hit.sample_x = inter.y - floor(inter.y)
                end
            end

            hit.hit_pos.x = inter.x
            hit.hit_pos.y = inter.y
        end
    end

    return hit or false
end

function Art:draw_columns(x1, x2)
    for x = x1, x2 do
        -- float fRayAngle = (fCameraHeading - (fFieldOfView / 2.0f)) + (float(x) / vFloatScreenSize.x) * fFieldOfView;
        local angle = self.camera.heading - (self.camera.fov / 2.0) + (x / self.canvas:getWidth()) * self.camera.fov
        local ray_dir = mv2(cos(angle), sin(angle))
        local len = 9999.0
        local hit = self:cast_ray(ray_dir)
        if hit then
            local ray = {
                x = hit.hit_pos.x - self.camera.pos.x,
                y = hit.hit_pos.y - self.camera.pos.y
            }
            len = magnitude(ray) * cos(angle - self.camera.heading)
        end

        local ch = self.canvas:getHeight()
        local ceiling = (ch / 2.0) - (ch / len)
        local flr = ch - ceiling
        local wall_height = flr - ceiling

        for y = 0, ch - 1 do
            if y < floor(ceiling) then
                local plane_z = (ch / 2) / ((ch / 2.0) - y)
                local r = plane_z * 2.0 / cos(angle - self.camera.heading)

                local plane_point = mv2(self.camera.pos.x + ray_dir.x * r, self.camera.pos.y + ray_dir.y * r)
                local plane_tile = mv2(floor(plane_point.x), floor(plane_point.y))
                local plane_sample = mv2(plane_point.x - plane_tile.x, plane_point.y - plane_tile.y)

                local pixel = self:select_scenery_pixel(plane_tile.x, plane_tile.y, CellSides.T, plane_sample, plane_z)
                self.canvas:setPixel(x, y, table.unpack(pixel))
            elseif (y > floor(ceiling) and y <= floor(flr)) and hit then
                local sample_y = (y - ceiling) / wall_height
                local pixel = self:select_scenery_pixel(hit.tile_pos.x, hit.tile_pos.y, hit.side, {
                    x = hit.sample_x,
                    y = sample_y
                }, len)
                self:depth_draw(x, y, len, pixel)
            else
                local plane_z = (ch / 2.0) / (y - (ch / 2.0))
                local plane_point = {
                    x = self.camera.pos.x + ray_dir.x * plane_z * 2.0 / cos(angle - self.camera.heading),
                    y = self.camera.pos.y + ray_dir.y * plane_z * 2.0 / cos(angle - self.camera.heading)
                }
                local plane_tile = {
                    x = floor(plane_point.x),
                    y = floor(plane_point.y)
                }
                local plane_sample = {
                    x = plane_point.x - plane_tile.x,
                    y = plane_point.y - plane_tile.y
                }

                local pixel = self:select_scenery_pixel(x, y, CellSides.B, plane_sample, plane_z)
                self.canvas:setPixel(x, y, table.unpack(pixel))
            end
        end
    end
end

function Art:draw()
    -- draw 2d
    local pre = { love.graphics.getColor() }

    table.sort(self.pics, function(a, b) return a.layer < b.layer end)

    for i = 1, #self.pics do
        local pic = self.pics[i]
        love.graphics.setColor(table.unpack(pic.color))
        if pic.kind == "rect" then
            love.graphics.rectangle("fill", pic.x, pic.y, pic.w, pic.h)
        elseif pic.kind == "line_rect" then
            love.graphics.rectangle("line", pic.x, pic.y, pic.w, pic.h)
        elseif pic.kind == "circle" then
            love.graphics.circle("fill", pic.x, pic.y, pic.radius)
        elseif pic.kind == "poly" then
            love.graphics.polygon("fill", pic.vertices)
        elseif pic.kind == "print" then
            love.graphics.print(pic.text, pic.font, pic.x, pic.y)
        elseif pic.kind == "typography" then
            love.graphics.print(pic.text, pic.font, pic.x, pic.y)
        elseif pic.kind == "paint" then
            love.graphics.draw(
                pic.drawable,
                pic.x,
                pic.y,
                pic.r,
                pic.sx,
                pic.sy
            )
        end
    end
    love.graphics.setColor(pre)

    self.pics = {}
    _layer = 0
end

return Art
