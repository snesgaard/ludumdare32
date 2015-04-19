require "actor"
require "entity"
require ("actors/soundwave")

local keybuffer = {
  [" "] = 0.3
}

local latchtable = {

}

local function pressed(f, k)
  local t = f.keyboard[k] or -1e300
  local l = latchtable[k] or -1e300
  local buffer = keybuffer[k] or 0.1
  return (t > l) and (love.timer.getTime() - t < buffer)
end

local function latch(k)
  latchtable[k] = love.timer.getTime()
end

local bongo = actor.new()

-- Idle state
local idleid = "idle"
fsm.vertex(bongo.control, idleid,
  function(c, f)
    local a = c.animations[idleid]
    a:update(f.dt)
  end,
  function(c, f)
    local a = c.animations[idleid]
    a:reset()
  end
)
bongo.visual[idleid] = function(c)
  local a = c.animations[idleid]
  actor.drawsprite(c.entity, a)
end

-- Walk state
local walkid = "walk"
fsm.vertex(bongo.control, walkid,
  function(c, f)
    local a = c.animations[walkid]
    a:update(f.dt)

    local r = love.keyboard.isDown("right")
    if r then
      c.entity.vx = 50
      c.entity.face = "right"
    else
      c.entity.vx = -50
      c.entity.face = "left"
    end
  end,
  function(c, f)
  end,
  function(c, f)
    c.entity.vx = 0
  end
)
bongo.visual[walkid] = function(c)
  local a = c.animations[walkid]
  actor.drawsprite(c.entity, a)
end

-- Left state
local leftid = "left"
fsm.vertex(bongo.control, leftid,
  function(c, f)
    local a = c.animations[leftid]
    a:update(f.dt)
  end,
  function(c, f)
    local a = c.animations[leftid]
    a:setMode("once")
    a:reset()
    a:play()

    local dx = 0
    if c.entity.face == "left" then dx = -dx end
    local w = newSoundWave(c.entity.x - dx, c.entity.y - 3, 120, "left", "player")
    table.insert(_global.actors, w)

    c.sound.leftbongo:rewind()
    love.audio.play(c.sound.leftbongo)

    local l = _global.actors.composer.context.leftnode()
    _global.actors.composer.addnode(l)
    _global.actors.banana.context.input["left"] = love.timer.getTime()
  end
)
bongo.visual[leftid] = function(c)
  local a = c.animations[leftid]
  actor.drawsprite(c.entity, a)
end

-- Right state
local rightid = "right"
fsm.vertex(bongo.control, rightid,
  function(c, f)
    local a = c.animations[rightid]
    a:update(f.dt)
  end,
  function(c, f)
    local a = c.animations[rightid]
    a:setMode("once")
    a:reset()
    a:play()

    local dx = 0
    if c.entity.face == "left" then dx = -dx end
    local w = newSoundWave(c.entity.x - dx, c.entity.y - 3, 120, "right", "player")
    table.insert(_global.actors, w)

    c.sound.rightbongo:rewind()
    love.audio.play(c.sound.rightbongo)

    local r = _global.actors.composer.context.rightnode()
    _global.actors.composer.addnode(r)
    _global.actors.banana.context.input["right"] = love.timer.getTime()
  end
)
bongo.visual[rightid] = function(c)
  local a = c.animations[rightid]
  actor.drawsprite(c.entity, a)
end

-- Arial state
local arialid = "arial"
fsm.vertex(bongo.control, arialid,
  function(c, f)
    local a = c.animations[arialid]
    a:update(f.dt)

    local r = love.keyboard.isDown("right")
    local l = love.keyboard.isDown("left")
    if r and not l then
      c.entity.vx = 50
      c.entity.face = "right"
    elseif l then
      c.entity.vx = -50
      c.entity.face = "left"
    else
      c.entity.vx = 0
    end
  end,
  function(c, f)
  end,
  function(c, f)
    c.entity.vx = 0
  end
)
bongo.visual[arialid] = function(c)
  local a = c.animations[arialid]
  actor.drawsprite(c.entity, a)
end

-- Edges
fsm.connect(bongo.control, idleid).to(walkid).when(
  function(c, f)
    local l = love.keyboard.isDown("left")
    local r = love.keyboard.isDown("right")
    if xor(l, r) then return 1 end
  end
)
fsm.connect(bongo.control, walkid).to(idleid).when(
  function(c, f)
    local l = love.keyboard.isDown("left")
    local r = love.keyboard.isDown("right")
    if not xor(l, r) then return 1 end
  end
)
fsm.connect(bongo.control, idleid, walkid, rightid, arialid).to(leftid).when(
  function(c, f)
    if pressed(f, "a") then
      latch("a")
      return 3
    end
  end
)
fsm.connect(bongo.control, leftid).to(idleid).when(
  function(c, f)
    local a = c.animations[leftid]
    if not a.playing then return 1 end
  end
)
fsm.connect(bongo.control, idleid, walkid, leftid, arialid).to(rightid).when(
  function(c, f)
    if pressed(f, "d") then
      latch("d")
      return 3
    end
  end
)
fsm.connect(bongo.control, rightid).to(idleid).when(
  function(c, f)
    local a = c.animations[rightid]
    if not a.playing then return 1 end
  end
)
fsm.connectall(bongo.control, arialid).when(
  function(c, f)
    local g = c.entity.ground
    if not g then
      return 2
    elseif pressed(f, " ") then
      latch(" ")
      c.entity.vy = 140
      return 3
    end
  end
)
fsm.connect(bongo.control, arialid).to(idleid).when(
  function(c, f)
    if c.entity.ground then return 1 end
  end
)

-- Init
bongo.control.current = idleid

bongo.context.animations = {
  [idleid] = loadanimation("res/bongoidle.png", 48, 48, 0.2, 0),
  [walkid] = loadanimation("res/bongowalk.png", 48, 48, 0.2, 0),
  [leftid] = loadanimation("res/bongoleft.png", 48, 48, 0.05, 0),
  [rightid] = loadanimation("res/bongoright.png", 48, 48, 0.05, 0),
  [arialid] = loadanimation("res/bongoarial.png", 48, 48, 0.05, 0),
}
bongo.context.sound = {
  leftbongo = love.audio.newSource("res/leftbongo.wav", "static"),
  rightbongo = love.audio.newSource("res/rightbongo.wav", "static")
}

bongo.context.entity = newEntity(100, -36 * 16, 4, 12)

bongo.context.entity.ground = false
bongo.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
  e.ground = (cy and cy < e.y)
end

return bongo
