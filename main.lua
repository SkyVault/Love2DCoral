local Coral = require("coral")()

Coral.sys.on_load(function()
  --Coral:save_game("coral")
  --Coral:load_game("coral")
end)

function love.load()
  Coral:load()
end

function love.update(dt)
  Coral:update(dt)
end

function love.draw()
  Coral:draw()
end
