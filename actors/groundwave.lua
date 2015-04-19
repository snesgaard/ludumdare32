require "actor"
require "entity"

function newGroundWave(x, y, face)
  local wave = actor.new()

  -- Alive state
  local aliveid = "alive"
  wave.visual[aliveid] = function(c)
    local e = c.entity
    love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
  end

  -- Dead state
  local deadid = "dead"

  --Edges
  fsm.connect(wave.control, aliveid).to(deadid).when(
    function(c, f)
      local lifetime = 5
      local t = love.timer.getTime()
      local r = t - c.spawntime
      if r > lifetime then return 1 end
    end
  )

  -- Init
  wave.control.current = aliveid
  wave.context.spawntime = love.timer.getTime()

  wave.context.entity = newEntity(x, y, 5, 5)

  wave.context.entity.face = face or wave.context.entity.face

  local vx = 50

  if wave.context.entity.face == "left" then vx = -vx end

  wave.context.entity.vx = vx

  return wave
end
