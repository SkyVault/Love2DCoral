return function(sys)
  local watchers = {

  }

  local function update(dt)
  end

  local function draw()
  end

  function watchers:watch(label, value)
  end

  sys.update(update)
  sys.draw(draw)

  return watchers
end
