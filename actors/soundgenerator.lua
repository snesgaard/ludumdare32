require "actor"
require "entity"
require ("actors/soundwave")
require "math"

function newWaveGenerator(x, y)
  local gen = actor.new()

  -- Idle state
  local idleid = "idle"
  fsm.vertex(gen.control, idleid,
    function(c, f)
    end,
    function(c, f)
      c.timer = love.timer.getTime()
    end
  )
  gen.visual[idleid] = function(c)
    local e = c.entity
    love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
  end

  -- Generative state
  local genid = "gen"
  fsm.vertex(gen.control, genid,
    function(c, f)
    end,
    function(c, f)
      local w = newSoundWave(c.entity.x, c.entity.y, 50, "left", "enemy")
      table.insert(_global.actors, w)
      c.sound.leftbongo:rewind()
      love.audio.play(c.sound.leftbongo)
    end
  )

  -- Damage state
  local damageid = "dmg"
  fsm.vertex(gen.control, damageid,
    function(c, f)
    end,
    function(c, f)
      c.start = love.timer.getTime()
    end,
    function(c, f)
      c.hit = nil
    end
  )
  gen.visual[damageid] = function(c)
    local e = c.entity
    local o = math.sin((love.timer.getTime() - c.start) * 60)  * 2
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("fill", e.x - e.wx + o, e.y - e.wy, e.wx * 2, e.wy * 2)
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Edges
  fsm.connect(gen.control, idleid).to(genid).when(
    function(c, f)
      if love.timer.getTime() - c.timer > 1 then
        return 1
      end
    end
  )
  fsm.connect(gen.control, genid).to(idleid).when(
    function(c, f)
      return 1
    end
  )
  fsm.connectall(gen.control, damageid).when(
    function(c, f)
      if c.hit then return 5 end
    end
  )
  local dmgduration = 1
  fsm.connect(gen.control, damageid).to(idleid).when(
    function(c, f)
      if love.timer.getTime() - c.start > dmgduration then return 1 end
    end
  )

  -- Init
  gen.control.current = idleid
  gen.context.timer = love.timer.getTime()

  gen.context.sound = {
    leftbongo = love.audio.newSource("res/leftbongo.wav", "static"),
  }

  gen.context.entity = newEntity(x, y, 5, 5)

  gen.hitbox = function(id, c)
    local e = c.entity
    local call = function()
    end
    local b = coolision.newAxisBox(e.x, e.y, e.wx, e.wy, call)
    b.hit = function(d)
      c.hit = love.timer.getTime()
    end
    return {b}
  end

  return gen
end
