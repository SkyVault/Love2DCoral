local timers = {}

function timer(timout, callback)
    table.insert(timers, { timout, callback })
end

OnUpdate(function(dt)
    for i = 1, #timers do
        timers[i][1] = timers[i][1] - dt

        if timers[i][1] <= 0 then
            timers[i][2]()
            table.remove(timers, i)
            return
        end
    end
end)
