require "actor"
require "entity"

local keybuffer = {
}

local latchtable = {

}

local function pressed(i, k)
  local t = i[k] or -1e300
  local l = latchtable[k] or -1e300
  local buffer = keybuffer[k] or 0.3
  return (t > l) and (love.timer.getTime() - t < buffer)
end

local function latch(k)
  latchtable[k] = love.timer.getTime()
end


local xjumpspeed = 50
local yjumpspeed = 150

local banana = actor.new()
local statehitbox = {}
local hitcache = {}

-- Idle state
local idleid = "idle"
fsm.vertex(banana.control, idleid,
  function(c, f)
  end,
  function(c, f)
    c.entity.vx = 0
  end,
  function(c, f)
    c.jump = nil
  end
)
banana.visual[idleid] = function(c)
  local a = c.animations[idleid]
  actor.drawsprite(c.entity, a)
end

-- Left jump state
local jumpleftid = "jumpleft"
fsm.vertex(banana.control, jumpleftid,
  function(c, f)
    local e = c.entity
    e.vx = -xjumpspeed
  end,
  function(c, f)
  end
)
banana.visual[jumpleftid] = function(c)
  local a = c.animations[idleid]
  actor.drawsprite(c.entity, a)
end

-- Right jump state
local jumprightid = "jumpright"
fsm.vertex(banana.control, jumprightid,
  function(c, f)
    local e = c.entity
    e.vx = xjumpspeed
  end,
  function(c, f)
  end
)
banana.visual[jumprightid] = function(c)
  local a = c.animations[idleid]
  actor.drawsprite(c.entity, a)
end

-- Pissed state
local pissedid = "pissed"
fsm.vertex(banana.control, pissedid,
  function(c, f)
    local a = c.animations[pissedid]
    a:update(f.dt)
  end,
  function(c, f)
    c.spawn = love.timer.getTime()
    c.entity.vx = 0
    c.entity.vy = 0
  end
)
banana.visual[pissedid] = function(c)
  local a = c.animations[pissedid]
  love.graphics.setColor(255, 50, 50, 255)
  actor.drawsprite(c.entity, a)
  love.graphics.setColor(255, 255, 255, 255)
end

-- Spin state
local spinid = "spin"
fsm.vertex(banana.control, spinid,
  function(c, f)
    local a = c.animations[spinid]
    a:update(f.dt)
    c.angle = (love.timer.getTime() - c.spawn) * 0.25
  end,
  function(c, f)
    c.spawn = love.timer.getTime()
    c.entity.vx = 0
    c.entity.vy = 250
  end
)
banana.visual[spinid] = function(c)
  local a = c.animations[spinid]
  actor.drawsprite(c.entity, a)
end
statehitbox[spinid] = function(c)
  local e = c.entity
  local call = function(other)
    if other.hit then other.hit(2) end
  end
  return {coolision.newAxisBox(e.x, e.y, e.wx, e.wy, call)}
end

-- Split states
local splittime = 0.5
local spitspeed = 200
local forwardsplitid = "fsplit"
fsm.vertex(banana.control, forwardsplitid,
  function(c, f)
    local a = c.animations[spinid]
    a:update(f.dt)
    local e = c.entity
    e.vx = 0
    e.vy = 0
    c.rad = (love.timer.getTime() - c.spawn) * spitspeed
  end,
  function(c, f)
    c.spawn = love.timer.getTime()
    hitcache = {}
  end
)
banana.visual[forwardsplitid] = function(c)
  local a = c.animations[spinid]
  local e = c.entity
  love.graphics.setColor(255, 255, 255, 100)
  actor.drawsprite({x = e.x + c.rad, y = e.y, face = "right"}, a)
  actor.drawsprite({x = e.x - c.rad, y = e.y, face = "left"}, a)
  love.graphics.setColor(255, 255, 255, 255)
end
local inversesplitid = "isplit"
fsm.vertex(banana.control, inversesplitid,
  function(c, f)
    local a = c.animations[spinid]
    a:update(f.dt)
    local e = c.entity
    e.vx = 0
    e.vy = 0
    c.rad = (splittime - love.timer.getTime() + c.spawn) * spitspeed
  end,
  function(c, f)
    c.spawn = love.timer.getTime()
    hitcache = {}
  end
)
banana.visual[inversesplitid] = function(c)
  local a = c.animations[spinid]
  local e = c.entity
  love.graphics.setColor(255, 255, 255, 100)
  actor.drawsprite({x = e.x + c.rad, y = e.y, face = "right"}, a)
  actor.drawsprite({x = e.x - c.rad, y = e.y, face = "left"}, a)
  love.graphics.setColor(255, 255, 255, 255)
end
local splithitbox = function(c)
  local e = c.entity
  local call = function(other)
    if not hitcache[other.globalid()] and other.hit then
      other.hit(1)
      hitcache[other.globalid()] = true
    end
  end
  local b = {
    coolision.newAxisBox(e.x + c.rad, e.y, e.wx, e.wy, call),
    coolision.newAxisBox(e.x - c.rad, e.y, e.wx, e.wy, call)
  }
  return b
end
statehitbox[forwardsplitid] = splithitbox
statehitbox[inversesplitid] = splithitbox

-- Edges
fsm.connect(banana.control, idleid, spinid).to(jumpleftid).when(
  function(c, f)
    if pressed(c.input, "left") then
      latch("left")
      c.entity.vy = yjumpspeed
      return 2
    end
  end
)
fsm.connect(banana.control, idleid, spinid).to(jumprightid).when(
  function(c, f)
    if pressed(c.input, "right") then
      latch("right")
      c.entity.vy = yjumpspeed
      return 2
    end
  end
)
fsm.connect(banana.control, jumpleftid, jumprightid, spinid).to(idleid).when(
  function(c, f)
    if c.entity.ground then return 1 end
  end
)
fsm.connectall(banana.control, pissedid).when(
  function(c, f)
    if pressed(c.input, "fail") then
      latch("fail")
      return 5
    end
  end
)
fsm.connectall(banana.control, spinid).except(pissedid).when(
  function(c, f)
    if pressed(c.input, "spin") then
      latch("spin")
      latch("right")
      latch("left")
      return 4
    end
  end
)
fsm.connectall(banana.control, forwardsplitid).except(pissedid).when(
  function(c, f)
    if pressed(c.input, "split") then
      latch("split")
      return 4
    end
  end
)
fsm.connect(banana.control, forwardsplitid).to(inversesplitid).when(
  function(c, f)
    if love.timer.getTime() - c.spawn > splittime then return 2 end
  end
)
fsm.connect(banana.control, inversesplitid).to(idleid).when(
  function(c, f)
    if love.timer.getTime() - c.spawn > splittime then return 2 end
  end
)
--fsm.connect(banana.control, forwardsplit).to(inversesplit)
local pissedtime = 0.2
fsm.connect(banana.control, pissedid).to(idleid).when(
  function(c, f)
    if love.timer.getTime() - c.spawn > pissedtime then return 1 end
  end
)

-- Init
banana.control.current = idleid

banana.context.entity = newEntity(100, -36 * 16, 8, 8)
banana.context.entity.ground = false
banana.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
  e.ground = (cy and cy < e.y)
end

banana.context.input = {}

banana.hitbox = function(id, c)
  local f = statehitbox[id]
  if f then return f(c) end
end

banana.context.animations = {
  [idleid] = loadanimation("res/bananaidle.png", 48, 48, 0.2, 0),
  [pissedid] = loadanimation("res/bananapissed.png", 48, 48, 0.05, 0),
  [spinid] = loadanimation("res/bananaspin.png", 48, 48, 0.05, 0),
}

return banana
