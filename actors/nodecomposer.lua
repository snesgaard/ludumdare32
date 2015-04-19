require "actor"
require "entity"
require "bit"
require ("actors/groundwave")

local keybuffer = {
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

local maxnodes = 3

local function encodenode(nodes)
  local n = 0
  if #nodes == maxnodes then
    for i = 1, maxnodes do
      n = bit.bor(n, bit.lshift(nodes[i], i - 1))
    end
    return n
  end
  return -1
end

local composer = actor.new()

local leftnode = 0
local rightnode = 1


-- Banana state
local bananaid = "banana Jump"
fsm.vertex(composer.control, bananaid,
  function(c, f)
  end,
  function(c, f)
    _global.actors.banana.context.input["spin"] = love.timer.getTime()
  end
)
composer.visual[bananaid] = function(c)

end
local splitid = "banana Split"
fsm.vertex(composer.control, splitid,
  function(c, f)
  end,
  function(c, f)
    _global.actors.banana.context.input["split"] = love.timer.getTime()
  end
)
local warpid = "bananaport"
fsm.vertex(composer.control, warpid,
  function(c, f)
  end,
  function(c, f)
    local me = _global.actors.main.context.entity
    local be = _global.actors.banana.context.entity
    me.x = be.x
    me.y = be.y
  end
)


-- Idle state
local idleid = "idle"
fsm.vertex(composer.control, idleid,
  function()
  end,
  function(c, f)
    c.nodes = {}
  end,
  function(c, f)
  end
)
composer.visual[idleid] = function(c)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(3)
  love.graphics.setColor(255, 255, 255, 100)
  love.graphics.rectangle("fill", 10, 12, maxnodes * 25 + 5, 26)
  table.foreach(c.nodes,
    function(i, n)
      if n then
        if n == leftnode then
          love.graphics.setColor(0, 255, 0, 255)
        elseif n == rightnode then
          love.graphics.setColor(0, 0, 255, 255)
        end
        local x = 25 + (i - 1) * 25
        love.graphics.circle("fill", x, 25, 10, 20)
      end
    end
  )
  love.graphics.setColor(255, 255, 255, 255)
  local en = encodenode(c.nodes)
  if en then
    local helptext = {
      [encodenode({1, 0, 1})] = bananaid,
      [encodenode({0, 0, 1})] = splitid,
      [encodenode({0, 1, 0})] = warpid
    }
    local ht = helptext[en]
    if ht then love.graphics.print(ht, 15, 40) end
  end
  love.graphics.pop()
end

-- Activate state
local activeid = "active"
fsm.vertex(composer.control, activeid,
  function(c, f)
  end,
  function(c, f)
  end,
  function(c, f)
    c.nodes = {}
  end
)

-- Fail state
local failid = "fail"
fsm.vertex(composer.control, failid,
  function(c, f)
  end,
  function(c, f)
    c.sounds.fail:rewind()
    love.audio.play(c.sounds.fail)
    _global.actors.banana.context.input["fail"] = love.timer.getTime()
  end
)
composer.visual[failid] = function(c)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(3)
  love.graphics.setColor(255, 0, 0, 100)
  local w = maxnodes * 25 + 5
  love.graphics.rectangle("fill", 10, 12, w, 26)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.setLineWidth(2)
  love.graphics.line(10, 12, 10 + w, 12 + 26)
  love.graphics.line(10 + w, 12, 10, 12 + 26)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.pop()
end

-- Edges
fsm.connect(composer.control, activeid).to(bananaid).when(
  function(c, f)
    if encodenode(c.nodes) == c.melodies[bananaid] then return 2 end
  end
)
fsm.connect(composer.control, activeid).to(splitid).when(
  function(c, f)
    if encodenode(c.nodes) == c.melodies[splitid] then return 2 end
  end
)
fsm.connect(composer.control, activeid).to(warpid).when(
  function(c, f)
    if encodenode(c.nodes) == c.melodies[warpid] then return 2 end
  end
)
fsm.connect(composer.control, idleid).to(activeid).when(
  function(c, f)
    if pressed(f, "s") then
      latch("s")
      return 1
    end
  end
)
fsm.connect(composer.control, activeid).to(failid).when(
  function(c, f)
    return 1
  end
)
fsm.connect(composer.control, failid).to(idleid).when(
  function(c, f)
    if not c.sounds.fail:isPlaying() then return 1 end
  end
)
fsm.connect(composer.control, bananaid, splitid, warpid).to(idleid).when(
  function(c, f)
    return 1
  end
)

-- Init
composer.control.current = idleid

composer.context.sounds = {
  fail = love.audio.newSource("res/fail.wav", "static")
}

composer.context.leftnode = function() return leftnode end
composer.context.rightnode = function() return rightnode end
composer.context.nodes = {}
composer.context.melodies = {
  [bananaid] = encodenode({1, 0, 1}),
  [splitid] = encodenode({0, 0, 1}),
  [warpid] = encodenode({0, 1, 0})
}

function composer.addnode(n)
  if composer.control.current == idleid then
    local c = composer.context
    local prev = n
    for x = 1, maxnodes do
      tmp = c.nodes[x]
      c.nodes[x] = prev
      prev = tmp
    end
  end
end

return composer
