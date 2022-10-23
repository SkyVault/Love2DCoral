return function(love, sys, art, tools, input)
  local ext, aabb = tools.ext, tools.aabb
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
    table.insert(self.containers, { x, y, width, height })
  end

  function ui:pop_container()
    table.remove(self.containers, #self.containers)
  end

  function ui.create_theme(overrides)
    return ext({
      bg_color = {0.2, 0.2, 0.2, 0.95},
      fg_color =  Maroon,
      font = love.graphics.newFont(18),
      title_font = love.graphics.newFont(24),
      margin = 8,
      padding = 8,
    }, overrides or {})
  end

  function ui:push_theme(overrides)
    table.insert(theme_stack, self.create_theme(ui.theme))
    self.theme = ext(self.theme, overrides)
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

  function ui:label(text)
    local fnt, w, h = self.theme.font, self:measure_text(text)
    ui:next_size(w, h)
    art.text(text, self.theme.font, self.cursor.x, self.cursor.y):color_(White)
    self:move_cursor(w, h)
  end

  function ui:title(text)
    local fnt, w, h = self.theme.title_font, self:measure_title(text)
    self:newline()
    art.text(text, self.theme.title_font, self.cursor.x, self.cursor.y):color_(Blue)
    self:newline()
  end

  function ui:divider()
    local x, y, w, h = table.unpack(self:container())
    local p = self.theme.padding
    local h = 6
    self:newline()
    art.rect(x + p, self.cursor.y + h/2, w - p * 2, 4):color_(DarkGray)
    self:newline(h + p)
  end

  function ui:newline(height)
    local x, y, w, h = table.unpack(self:container())
    self.cursor.x = x
    self.cursor.y = self.cursor.y + (height or math.max(self.max_height, self.theme.font:getHeight()))
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
    art.rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.bg_color)
    art.line_rect(self.cursor.x, self.cursor.y, w, h):color_(White)
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
    art.rect(self.cursor.x, self.cursor.y, w, h):color_(self.theme.bg_color)
    art.line_rect(self.cursor.x, self.cursor.y, w, h):color_(White)
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

    self:next_size(w, h)
    self:move_cursor(w, h)

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

  sys.on_load(load)
  sys.on_update(update)
  sys.on_draw(draw)

  return ui
end
