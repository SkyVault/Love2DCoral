return function(love, sys, art, tools)
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
    art.line_rect(x, y, width, height):color_(Green)
  end

  function ui:pop_container()
    table.remove(self.containers, #self.containers)
  end

  function ui.create_theme(overrides)
    return ext({
      bg_color = {0.2, 0.2, 0.2, 0.95},
      fg_color =  Maroon,
      font = love.graphics.newFont(24),
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

  function ui:panel(width, height)
    width = width + ui.theme.padding
    height = height + ui.theme.padding

    self:next_size(width, height)
    art.rect(self.cursor.x, self.cursor.y, width, height):color_(self.theme.bg_color)
    self:move_cursor(width, height)
  end

  function ui:label(text)
    local fnt = self.theme.font
    local w, h = fnt:getWidth(text) + self.theme.padding, fnt:getHeight() + self.theme.padding
    ui:next_size(w, h)
    art.text(text, self.theme.font, self.cursor.x, self.cursor.y):color_(White)
    self:move_cursor(w, h)
  end

  function ui:button(text)
    local fnt = self.theme.font
    local w, h = fnt:getWidth(text) + self.theme.padding, fnt:getHeight() + self.theme.padding
    ui:next_size(w, h)
    local mx, my = love.mouse.getPosition()
    local ox, oy = self.cursor.x, self.cursor.y

    local hot = point_intersects_rect(
      v2(mx, my),
      { x = ox, y = oy, width = w, height = h }
    )

    local old = ui.theme.bg_color
    local ml = love.mouse.isDown(1)

    if hot then ui.theme.bg_color = { 0.4, 0.4, 0.45, 0.99 } end
    if hot and ml then ui.theme.bg_color = { 0.4, 0.4, 0.85, 0.99 } end

    self:panel(w - self.theme.padding, h - self.theme.padding)
    art.text(text, fnt, ox + self.theme.padding / 2, oy + self.theme.padding / 2):color_(White)

    if hot then ui.theme.bg_color = old end

    return hot and love.mouse.isDown(1)
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
