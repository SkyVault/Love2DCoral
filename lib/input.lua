return function(love, sys, set)
  local keys = {}
  local reg = {}
  local mouses = {}
  local mreg = {}

  local function is_down(k)
    local now = love.keyboard.isDown(k)
    keys[k] = now
    return now
  end

  local function is_up(k)
    local now = love.keyboard.isDown(k)
    keys[k] = now
    return now
  end

  local function is_pressed(k)
    local now, last = love.keyboard.isDown(k), keys[k]
    return now and not last
  end

  local function is_released(k)
    local now, last = love.keyboard.isDown(k), keys[k]
    return not now and last
  end

  local function is_mouse_pressed(b)
    local now, last = love.mouse.isDown(b), mouses[b]
    return now and not last
  end

  local function is_mouse_released(b)
    local now, last = love.mouse.isDown(b), mouses[b]
    return not now and last
  end

  sys.update(function()
    for i = 1, 3 do
      mouses[i] = mouses[i] == nil and false or love.mouse.isDown(i)
    end

    for k, v in pairs(reg) do
      keys[k] = love.keyboard.isDown(k)
    end
  end, 9999)

  sys.keypressed(function(k) reg[k] = true end)
  sys.keyreleased(function(k) reg[k] = false end)

  return {
    is_down = is_down,
    is_up = is_up,
    is_pressed = is_pressed,
    is_released = is_released,
    is_mouse_pressed = is_mouse_pressed,
    is_mouse_released = is_mouse_released,
  }
end
