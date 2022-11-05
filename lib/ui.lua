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

  function ui:pop_container()
    table.remove(self.containers, #self.containers)
  end

  function ui.create_theme(overrides)
    return ext({
      bg_color = {0.2, 0.2, 0.2, 0.95},
      fg_color =  LightGray,
      font = love.graphics.newFont(18),
      title_font = love.graphics.newFont(24),
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
      :color_(White)
      self.cursor.y = self.cursor.y + h
    end

    art.rect(self.cursor.x, self.cursor.y, width, height)
      :color_(self.theme.bg_color)
      :corner_radius_(8)
  end

  function ui:label(text)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    ui:next_size(w, h)
    art.text(text, self.theme.font, self.cursor.x, self.cursor.y):color_(White)
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

    if #tbl > 0 then
      local startx, cursorx = 0, 0
      local starty, cursory = 0, 0
      for i = 1, #tbl do
        local s, fnt = tostring(tbl[i]), ui.theme.font
        local w, h = fnt:getWidth(s), fnt:getHeight()
        cursorx = cursorx + w + self.theme.margin
        if cursory == 0 then cursory = h end
        table.insert(ps, { v = s, w = w, h = h })
      end
      local w = cursorx - startx + self.theme.margin / 2
      local h = cursory - starty

      ui:rpanel(w, h, label)

      for i = 1, #ps do
        local p = ps[i]
        if type(p.v) ~= "table" then
          local text = tostring(p.v)
          art.text(text, font, self.cursor.x, self.cursor.y):color_(White)
          self:move_cursor(p.w, p.h)
        end
      end
    else
      
      for k, v in pairs(tbl) do
        if type(v) ~= "table" then
          local key, value = font:getWidth(k), font:getWidth(tostring(v))
          art.text(k, font, self.cursor.x, self.cursor.y):color_(White):layer_(0.1)
          self.cursor.x = self.cursor.x + key
          art.text(tostring(v), font, self.cursor.x, self.cursor.y):color_(White):layer_(0.1)
          self.cursor.x = self.cursor.x - key
          self.cursor.y = self.cursor.y + font:getHeight()
        end
      end

    end

  end

  function ui:button(text)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    ui:next_size(w, h)
    local ox, oy = self.cursor.x, self.cursor.y

    local hot = self:is_hot(w, h)
    local old = ui.theme.bg_color
    local ml = love.mouse.isDown(1)

    if hot then ui.theme.bg_color = { 0.4, 0.4, 0.45, 0.99 } end
    if hot and ml then ui.theme.bg_color = { 0.4, 0.4, 0.85, 0.99 } end

    self:next_size(w, h)
    art.rect(self.cursor.x + 4, self.cursor.y + 4, w, h):color_({0, 0, 0, 0.5})
    art.rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.bg_color)
    art.line_rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.fg_color)
    self:move_cursor(w, h)

    art.text(text, fnt, ox + self.theme.padding / 2, oy + self.theme.padding / 2):color_(White)

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

    art.text(text, fnt, ox + self.theme.padding / 2, oy + self.theme.padding / 2):color_(White)

    if hot or checked then ui.theme.bg_color = old end

    if hot and input.is_mouse_pressed(1) then
      return not checked
    else
      return checked
    end
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
  end

  sys.load(load)
  sys.update(update)
  sys.draw(draw)

  return ui
end
