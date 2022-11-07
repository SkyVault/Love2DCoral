return function(sys, ui, hash)
  local watchers = {
    xs = {},
  }

  local function update(dt)
    for k, v in pairs(watchers.xs) do

      local w, h, val = v.width, v.height, v.value

      --local font = ui.theme.font
      --local ww = font:getWi
      --tostring(val)

      ui:push_container(0, 0, w, h)

      if type(val) ~= "table" then
        ui:title(tostring(val))
      else
        ui:table(val, k)
      end

      ui:pop_container()
    end
  end

  local function draw()
  end

  function watchers:watch(label, value, unique_id)
    self.xs[unique_id] = {
      value = value,
      label = label,
      width = 0,
      height = 0
    }
  end

  function watchers:unwatch(unique_id)
    watchers.xs[unique_id] = nil
  end

  sys.update(update)
  sys.draw(draw)

  return setmetatable(watchers, {
    __call = function(self, value, uid)
      watchers:watch("", value, uid)
    end
  })
end
