return function()
  local events = {}

  local function event(id)
    events[id] = {}
  end

  local function listen(id, fn)
    assert(events[id], "invalid event id: " .. tostring(id))
    table.insert(events[id], fn)
  end

  local function emit(id, ...)
    local ls = events[id]
    for i = 1, #ls do
      ls[i](...)
    end
  end

  local function send(id)
    local ls = events[id]
    for i = 1, #ls do
      ls[i]()
    end
  end

  return {
    event = event,
    listen = listen,
    emit = emit,
    send = send,
  }
end
