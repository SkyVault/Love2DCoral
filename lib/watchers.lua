return function(sys)
  local watchers = {

  }

  local function update(dt)
  end

  local function draw()
  end

  function watchers:watch(label, value)
  end

  sys.on_update(update)
  sys.on_draw(draw)

  return watchers
end
