return function(record)
  return record("Clock") {
    delta = 0,
    fps = 0,
    ticks = 0,
    timer = 0,
    average_delta = 0,

    _dt_coll = {},

    update = function(self, dt)
      table.insert(self._dt_coll, dt)
      if #self._dt_coll > 10 then
        local av = 0
        for i = 1, #self._dt_coll do
          av = av + self._dt_coll[i] / #self._dt_coll
        end
        self.average_delta = av
        self._dt_coll = {}
      end

      if self.average_delta == 0 and dt > 0 then
        self.average_delta = dt
      end

      self.timer = self.timer + dt
      self.delta = dt
      self.fps = math.floor(self.average_delta == 0 and (dt == 0 and 0 or 1 / dt) or 1 / self.average_delta)
      self.ticks = self.ticks + 1
    end,
  }
end
