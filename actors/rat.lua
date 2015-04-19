require "actor"
require "entity"
require "math"

rats = 0

function newRat(x, y)
  local rat = actor.new()

  -- Idle state
  local idleid = "idle"
  fsm.vertex(rat.control, idleid,
    function(c, f)
      local a = c.animations[idleid]
      a:update(f.dt)
    end,
    function(c, f)
      c.walktimer = love.timer.getTime()
    end
  )
  rat.visual[idleid] = function(c)
    local a = c.animations[idleid]
    actor.drawsprite(c.entity, a)
  end

  -- Walk state
  local walkid = "walk"
  local rightid = "right"
  local speed = 25
  fsm.vertex(rat.control, rightid,
    function(c, f)
      local a = c.animations[walkid]
      a:update(f.dt)
      local e = c.entity
      e.vx = speed
      e.face = "right"
    end,
    function(c, f)
      c.walktimer = love.timer.getTime()
    end,
    function(c, f)
      c.entity.vx = 0
    end
  )
  local leftid = "left"
  fsm.vertex(rat.control, leftid,
    function(c, f)
      local a = c.animations[walkid]
      a:update(f.dt)
      local e = c.entity
      e.vx = -speed
      e.face = "left"
    end,
    function(c, f)
      c.walktimer = love.timer.getTime()
    end,
    function(c, f)
      c.entity.vx = 0
    end
  )
  local function drawwalk(c)
    local a = c.animations[walkid]
    actor.drawsprite(c.entity, a)
  end
  rat.visual[rightid] = drawwalk
  rat.visual[leftid] = drawwalk

  --Damage State
  local damageid = "dmg"
  fsm.vertex(rat.control, damageid,
    function(c, f)

    end,
    function(c, f)
      c.dmgtimer = love.timer.getTime()
      c.hp = c.hp - c.hit
    end,
    function(c, f)
      c.hit = nil
    end
  )
  rat.visual[damageid] = function(c)
    local a = c.animations[damageid]
    local e = c.entity
    local o = love.timer.getTime() * 60
    local fe = {x = e.x + math.sin(o) * 2, y = e.y, face = e.face}
    love.graphics.setColor(255, 0, 0, 255)
    actor.drawsprite(fe, a)
    love.graphics.setColor(255, 255, 255, 255)
  end

  --Dying state
  local dyingid = "dying"
  local dyingtime = 0.5
  fsm.vertex(rat.control, dyingid,
    function(c, f)
    end,
    function(c, f)
      c.dyingtimer = love.timer.getTime()
      rats = rats - 1
    end,
    function(c, f)
    end
  )
  rat.visual[dyingid] = function(c)
    local a = c.animations[damageid]
    local s = (dyingtime - (love.timer.getTime() - c.dyingtimer)) / dyingtime
    love.graphics.setColor(255, 0, 0, 255)
    actor.drawsprite(c.entity, a, s)
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Dead state
  local deadid = "dead"

  -- Edges
  local idletime = 2
  fsm.connect(rat.control, idleid).to(leftid).when(
    function(c, f)
      local t = love.timer.getTime() - c.walktimer
      if c.entity.face == "right" and t > idletime then return 1 end
    end
  )
  fsm.connect(rat.control, idleid).to(rightid).when(
    function(c, f)
      local t = love.timer.getTime() - c.walktimer
      if c.entity.face == "left" and t > idletime then return 1 end
    end
  )
  local walktime = 3.0
  fsm.connect(rat.control, rightid, leftid).to(idleid).when(
    function(c, f)
      local t = love.timer.getTime() - c.walktimer
      if t > walktime then return 1 end
    end
  )
  local damagetime = 0.25
  fsm.connect(rat.control, damageid).to(idleid).when(
    function(c, f)
      if love.timer.getTime() - c.dmgtimer > damagetime then return 1 end
    end
  )
  fsm.connect(rat.control, damageid).to(dyingid).when(
    function(c, f)
      if c.hp <= 0 then return 5 end
    end
  )
  fsm.connect(rat.control, dyingid).to(deadid).when(
    function(c, f)
      if love.timer.getTime() - c.dyingtimer > dyingtime then return 1 end
    end
  )
  fsm.connectall(rat.control, damageid).except(dyingid).when(
    function(c, f)
      if c.hit then return 5 end
    end
  )

  -- Init
  rat.control.current = idleid
  rat.context.entity = newEntity(x, y, 13, 4)

  rat.context.walktimer = love.timer.getTime()
  rat.context.hp = 2

  rat.context.animations = {
    [idleid] = loadanimation("res/ratidle.png", 48, 48, 0.2, 0),
    [walkid] = loadanimation("res/ratwalk.png", 48, 48, 0.2, 0),
    [damageid] = loadanimation("res/ratdamage.png", 48, 48, 0.2, 0),
  }

  rat.hitbox = function(id, c)
    local e = c.entity
    local call = function()
    end
    local b = coolision.newAxisBox(e.x, e.y, e.wx, e.wy + 4, call)
    b.hit = function(d)
      c.hit = d
    end
    return {b}
  end

  rats = rats + 1
  return rat
end
