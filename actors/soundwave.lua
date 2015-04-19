require "actor"
require "entity"

local type2color = {
  left = {0, 255, 0},
  right = {0, 0, 255},
  pissed = {255, 0, 0},
}

function newSoundWave(x, y, speed, type, faction)
  local wave = actor.new()

  -- Alive state
  local aliveid = "alive"
  fsm.vertex(wave.control, aliveid,
    function(c, f)
      local t = love.timer.getTime()
      c.rad = (t - c.spawntime) * speed
    end
  )
  wave.visual[aliveid] = function(c)
    local r, g, b = unpack(type2color[type])
    local rad = c.rad
    love.graphics.setColor(r, g, b, 100)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", c.x, c.y, rad, 100)
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Dead state
  local deadid = "dead"

  --Edges
  fsm.connect(wave.control, aliveid).to(deadid).when(
    function(c, f)
      local lifetime = 3
      local t = love.timer.getTime()
      local r = t - c.spawntime
      if r > lifetime or c.dead then return 1 end
    end
  )

  -- Init
  wave.control.current = aliveid
  wave.context.spawntime = love.timer.getTime()
  wave.context.x = x
  wave.context.y = y
  wave.context.rad = 0

  return wave
end
