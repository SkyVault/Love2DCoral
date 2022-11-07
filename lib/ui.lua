return function(love, sys, art, tools, input, vault, palette)
  local fmt = string.format
  local ext, aabb = vault.ext, tools.aabb
  local point_intersects_rect = tools.point_intersects_rect

  local theme_stack = {}

  local ui = {
    cursor = v2(),
    theme = {},
    containers = {},
    max_height = 0,

    style_stack = {},

    windows = {},
  }

  function ui:container()
    return self.containers[#self.containers]
  end

  function ui:push_container(x, y, width, height)
    self.cursor.x = x
    self.cursor.y = y
    self.max_height = 0
    table.insert(self.containers, { x, y, width, height })
  end

  function ui:style(style)
    for i = #self.style_stack, 1, -1 do
      local s = self.style_stack[i]
      if s == style then
        return true
      end
    end
    return false
  end

  function ui:grow_width()
    table.insert(self.style_stack, "grow_width")
    return self
  end

  function ui:text_underline()
    table.insert(self.style_stack, "text_underline")
    return self
  end

  function ui:pop_container()
    table.remove(self.containers, #self.containers)
  end

  function ui.create_theme(overrides)
    return ext({
      bg_color = {0.2, 0.2, 0.2, 0.95},
      fg_color =  LightGray,
      font = love.graphics.newFont("res/Monoid Retina Nerd Font Complete Mono.ttf"),
      title_font = love.graphics.newFont(24),
      text_color = White,
      margin = 8,
      padding = 8,
    }, overrides or {})
  end

  function ui:push_theme(overrides)
    table.insert(theme_stack, self.create_theme(ui.theme))
    self.theme = ext(vault.copy(self.theme), overrides)
  end

  function ui:pop_theme()
    self.theme = ext(self.theme, self.create_theme(theme_stack[#theme_stack]))
    table.remove(theme_stack, #theme_stack)
  end

  ui.theme = ui.create_theme()

  function ui:next_size(width, height)
    local cx, cy, cw, ch = table.unpack(self:container())
    local x, y = self.cursor.x, self.cursor.y

    self.max_height = math.max(self.max_height, height)

    if x + width + self.theme.margin > cx + cw then
      self.cursor.x = cx
      self.cursor.y = self.cursor.y + self.max_height + self.theme.margin
      self.max_height = 0
    end
  end

  function ui:move_cursor(width, height)
    self.cursor.x = self.cursor.x + width + self.theme.margin
  end

  function ui:measure_text(text)
    local fnt = ui.theme.font
    return fnt:getWidth(text) + self.theme.padding, fnt:getHeight() + self.theme.padding
  end

  function ui:measure_title(text)
    local fnt = ui.theme.title_font
    return fnt:getWidth(text) + self.theme.padding, fnt:getHeight() + self.theme.padding
  end

  function ui:is_hot(w, h)
    local ox, oy = self.cursor.x, self.cursor.y
    return point_intersects_rect(
      v2(love.mouse.getX(), love.mouse.getY()),
      { x = ox, y = oy, width = w, height = h }
    )
  end

  function ui:panel(width, height)
    art.rect(self.cursor.x, self.cursor.y, width, height):color_(self.theme.bg_color)
  end

  function ui:rpanel(width, height, title)
    if title then
      local w, h = self.theme.font:getWidth(title), self.theme.font:getHeight() + ui.theme.margin
      art.rect(self.cursor.x, self.cursor.y + 6, w + ui.theme.margin * 2, h + height - 12 + 4)
        :color_({ 0.2, 0.3, 0.4, 1.0 })
        :corner_radius_(8)

      art.text(
        title,
        self.theme.font,
        self.cursor.x + ui.theme.margin,
        self.cursor.y + 6
      )
      :color_(ui.theme.text_color)
      self.cursor.y = self.cursor.y + h
    end

    art.rect(self.cursor.x, self.cursor.y, width, height)
      :color_(self.theme.bg_color)
      :corner_radius_(8)
  end

  function ui:paragraph(text)
  end

  function ui:label(text)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    ui:next_size(w, h)
    art.text(text, self.theme.font, self.cursor.x, self.cursor.y):color_(ui.theme.text_color)
    self:move_cursor(w, h)
  end

  function ui:title(text)
    local fnt, w, h = self.theme.title_font, self:measure_title(text)
    self:newline()
    art.text(text, self.theme.title_font, self.cursor.x, self.cursor.y + 4):color_(Black)
    art.text(text, self.theme.title_font, self.cursor.x, self.cursor.y):color_(Tan)
    self:newline(h)
  end

  function ui:divider()
    local x, y, w, _ = table.unpack(self:container())
    local p = self.theme.padding
    local h = 6
    self:newline()
    art.rect(x + p, self.cursor.y - h + 2, w - p * 2, 2):color_(DarkGray)
  end

  function ui:newline(height)
    local x, y, w, h = table.unpack(self:container())
    self.cursor.x = x
    self.cursor.y = self.cursor.y + self.theme.margin + (height or math.max(self.max_height, self.theme.font:getHeight()))
  end

  function ui:table(tbl, label)
    local ps, font = {}, self.theme.font
    local str = vault.write(tbl, true)

    ui:window(label, 400, 300, 200, 200, function(win)
      art.paragraph(str, font, win.x, win.y, win.w, "left")
        :color_(Orange)
        :layer_(1000)
      art.paragraph(str, font, win.x, win.y, win.w, "left")
        :color_(ui.theme.text_color)
        :layer_(1000)
    end)
  end

  function ui:button(text)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    local _, _, cw, _ = table.unpack(self:container())
    if ui:style "grow_width" then w = cw end

    local hot = self:is_hot(w, h)
    local old = ui.theme.bg_color
    local ml = love.mouse.isDown(1)

    if hot then ui.theme.bg_color = { 0.4, 0.4, 0.45, 0.99 } end
    if hot and ml then ui.theme.bg_color = { 0.4, 0.4, 0.85, 0.99 } end

    if ui:style "text_underline" then
      local fg = hot and Maroon or ui.theme.text_color
      art.text(
        text, fnt, self.cursor.x + self.theme.padding / 2, self.cursor.y + self.theme.padding / 2
      ):color_(fg):layer_(1.1)
      art.rect(self.cursor.x, self.cursor.y + h - 2, w, 2):color_(fg):layer_(1.0)
    else
      art.rect(self.cursor.x, self.cursor.y, w, h)
        :color_(self.theme.bg_color)
        :corner_radius_(4)
        :layer_(1.0)

      art.line_rect(self.cursor.x, self.cursor.y, w, h)
        :color_(self.theme.fg_color)
        :corner_radius_(4)
        :layer_(1.05)

      art.text(
        text, fnt, self.cursor.x + self.theme.padding / 2, self.cursor.y + self.theme.padding / 2
      ):color_(ui.theme.text_color):layer_(1.1)
    end

    self:move_cursor(w, h)
    self:next_size(w, h)

    if hot then ui.theme.bg_color = old end
    return hot and input.is_mouse_pressed(1)
  end

  function ui:toggle(text, checked)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    ui:next_size(w, h)
    local ox, oy = self.cursor.x, self.cursor.y

    local hot = self:is_hot(w, h)
    local old = ui.theme.bg_color
    local ml = love.mouse.isDown(1)

    if hot then ui.theme.bg_color = { 0.4, 0.4, 0.45, 0.99 } end
    if checked then ui.theme.bg_color = { 0.4, 0.4, 0.85, 0.99 } end

    self:next_size(w, h)
    art.rect(self.cursor.x + 4, self.cursor.y + 4, w, h):color_(Black)
    art.rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.bg_color)
    art.line_rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.fg_color)
    self:move_cursor(w, h)

    art.text(text, fnt, ox + self.theme.padding / 2, oy + self.theme.padding / 2):color_(ui.theme.text_color)

    if hot or checked then ui.theme.bg_color = old end

    if hot and input.is_mouse_pressed(1) then
      return not checked
    else
      return checked
    end
  end

  function ui:window(label, x, y, w, h, body)
    local ps, font = {}, self.theme.font
    local win = ui.windows[label]

    if ui.windows[label] == nil then
      ui.windows[label] = {
        show_menu = false,
        w = w or 200,
        h = h or 200,
        x = 32,
        y = 32,
        mx = 0,
        my = 0
      }
      win = ui.windows[label]
    end

    local cx, cy, cw, ch = win.x, win.y, win.w, win.h
    local sx, sy = cx + cw / 2 - 16, cy - 4
    local move_hot = point_intersects_rect(v2(love.mouse.getX(), love.mouse.getY()), { x = sx, y = sy - 2, width = 32, height = 12 })

    if input.is_mouse_pressed(1) and move_hot then
      win.mx, win.my = love.mouse.getX(), love.mouse.getY()
      win.dragging = true
    end

    if input.is_mouse_pressed(2) and move_hot then
      win.show_menu = not win.show_menu
    end

    if input.is_mouse_pressed(1) and not move_hot then
      win.show_menu = false
    end

    if win.show_menu then
      local xx, yy = sx - 64, sy + 8
      ui:push_container(xx + 8, yy + 8, 128 + 16, 128 + 64)
      art.rect(xx, yy, 128 + 32, 128 + 64)
        :corner_radius_(6)
        :color_({ 1, 1, 1, 0.8 })
        :layer_(1)

      local th = ui.theme

      local fg, bg, tc = th.fg_color, th.bg_color, th.text_color

      th.text_color = Black
      th.bg_color = White
      th.fg_color = { 0.8, 0.8, 0.8, 0.7 }
      ui:grow_width():text_underline()
      ui:button("close")

      ui:grow_width(); ui:button("top-left")
      ui:grow_width(); ui:button("top-right")
      ui:grow_width(); ui:button("bottom-left")
      ui:grow_width(); ui:button("bottom-right")

      th.fg_color, th.bg_color, th.text_color = fg, bg, tc

      ui:pop_container()
    end

    if input.is_mouse_down(1) then
      if win.dragging then
        local mx, my = love.mouse.getX(), love.mouse.getY()
        local dx, dy = win.mx - mx, win.my - my
        win.x = win.x - dx
        win.y = win.y - dy
        win.mx, win.my = mx, my
      end
    else
      win.dragging = false
    end
    win.w = math.max(win.w, 64)
    win.h = math.max(win.h, 64)

    cx, cy, cw, ch = win.x, win.y, win.w, win.h
    sx, sy = cx + cw / 2 - 16, cy - 4

    ui:push_container(win.x, win.y, cw, ch)

    if move_hot then
      love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
      art.rect(sx - 2, sy - 4, 34, 8):corner_radius_(4)
    else
      art.line(sx, sy, sx + 32, cy - 4)
    end

    art.crop(cx, cy, cw, ch, function()
      art.rect(cx, cy, cw, ch):color_({ 0.2, 0.1, 0, 0.5 }):corner_radius_(8)
      art.line_rect(cx, cy, cw, ch):corner_radius_(8)
      body(win)
    end)

    local resize_hot = point_intersects_rect(v2(love.mouse.getX(), love.mouse.getY()), { x = cx + cw - 4 - 7, y = cy + ch - 4 - 7, width = 24, height = 24 })

    if input.is_mouse_pressed(1) and resize_hot then
      win.mx, win.my = love.mouse.getX(), love.mouse.getY()
      win.resizing = true
    end

    if input.is_mouse_down(1) then
      if win.resizing then
        local mx, my = love.mouse.getX(), love.mouse.getY()
        local dx, dy = win.mx - mx, win.my - my
        win.w, win.h = win.w - dx, win.h - dy
        win.mx, win.my = mx, my
      end
    else
      win.dragging = false
    end

    if resize_hot then
      love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
      art.rect(cx + cw - 4 - 9, cy + ch - 4 - 2, 18, 4):color_(White):corner_radius_(3)
      art.rect(cx + cw - 4 - 2, cy + ch - 4 - 9, 4, 18):color_(White):corner_radius_(3)
    else
      art.rect(cx + cw - 4 - 7, cy + ch - 4 - 2, 14, 4):color_({ 0.9, 0.9, 0.9, 1.0 }):corner_radius_(2)
      art.rect(cx + cw - 4 - 2, cy + ch - 4 - 7, 4, 14):color_({ 0.9, 0.9, 0.9, 1.0 }):corner_radius_(2)
    end

    if not resize_hot and not move_hot then
      love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end

    ui:pop_container()
  end

  function ui:image_button(image)
    local w, h = image:getWidth(), image:getHeight()
    ui:next_size(w, h)
    local ox, oy = self.cursor.x, self.cursor.y

    local hot = self:is_hot(w, h)
    local old = ui.theme.bg_color
    local ml = love.mouse.isDown(1)

    local tint = White
    tint.a = 0.85
    if hot then tint = { 1.0, 1.0, 1.0, 1.0 } end
    if hot and ml then tint = { 0.9, 0.9, 1.0, 1.0 } end

    self:move_cursor(w, h)

    art.rect(ox + 4, oy + 4, w, h):color_(Black)
    art.image(image, ox, oy):color_(tint)

    if hot then ui.theme.bg_color = old end
    return hot and input.is_mouse_pressed(1)
  end

  local function load()
    ui.containers = {
      { 0, 0, love.graphics.getWidth(), love.graphics.getHeight() }
    }
  end

  local function update(dt)
  end

  local function draw()
    ui.cursor = v2()
    ui.style_stack = {}
  end

  sys.load(load)
  sys.update(update)
  sys.draw(draw)

  return ui
end
