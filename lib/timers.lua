
return function(sys)
  local timers = {
    ts = {}
  }

  function timers.timer(timeout, callback)
    local t = { timeout = timeout, callback = callback }
    table.insert(timers.ts, t)
    return t
  end

  sys.update(function(dt)
    for i = 1, #timers.ts do
      timers.ts[i].timeout = timers.ts[i].timeout - dt

      if timers.ts[i].timeout <= 0 then
        timers.ts[i].callback()
        table.remove(timers.ts, i)
        return
      end
    end
  end, -1)

  return timers
end
