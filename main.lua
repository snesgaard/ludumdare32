require ("modules/coolision")
require ("modules/tilephysics")
require ("modules/AnAL")
local sti = require ("modules/sti")
local misc = require ("modules/misc")
require ("actors/soundgenerator")
require ("actors/rat")

function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end

function xor(a, b)
  a = a or false
  b = b or false
  return (a or b) and (not (a and b))
end

function pressed(a)
  local buffer = 0.3
  a = a or -1e300
  return love.timer.getTime() - a < buffer
end

function love.keypressed(key, isrepeat)
  framedata.keyboard[key] = love.timer.getTime()
end

function love.load()
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)

  _global = {
    actors = {
      require ("actors/test"),
      main = require ("actors/bongoguy"),
      composer = require ("actors/nodecomposer"),
      banana = require ("actors/banana"),
      -- newWaveGenerator(200, 0),
    },
  }
  for i = 1, 8 do
    table.insert(_global.actors, newRat(200 + i * 50, -35 * 16))
  end
  for i = 1, 2 do
    table.insert(_global.actors, newRat(100 + i * 50, -26 * 16))
  end
  for i = 1, 24 do
    table.insert(_global.actors, newRat(200 + i * 10, -9 * 16))
  end
  for i = 1, 1 do
    table.insert(_global.actors, newRat(500 + i * 30, -18 * 16))
  end
  _global.map = sti.new("res/level1")
  misc.setPosSTIMap(_global.map, 0, 0)

  framedata = {
    keyboard = {

    },
  }
  _global.time = love.timer.getTime()
end

function love.update(dt)
  framedata.dt = dt

  -- Tilemap collisions
  if _global.map then
    _global.map:update(dt)
    table.foreach(_global.actors, function(_, a)
      if a.context.entity then
        mapAdvanceEntity(_global.map, "game", a.context.entity, dt)
      end
    end)
  end

  -- Hitbox collision
  local boxes = {}
  -- Gather submitted hitboxes from actors
  table.foreach(_global.actors,
    function(k, a)
      local submit = a.hitbox(a.control.current, a.context) or {}
      table.foreach(submit,
        function(_, subbox)
          subbox.globalid = function() return tostring(k) end
          table.insert(boxes, subbox)
        end
      )
    end
  )
  -- Run collision detection and callbacks
  local collisiontable = coolision.collisiondetect(boxes, 1, 0)
  table.foreach(collisiontable,
    function(boxa, collisions)
      table.foreach(collisions,
        function(_, boxb)
          if boxa.hitcallback then boxa.hitcallback(boxb) end
          if boxb.hitcallback then boxb.hitcallback(boxa) end
        end
      )
    end
  )

  table.foreach(_global.actors,
    function(k, a)
      actor.update(a, framedata)
    end
  )
  local terminate = {}
  table.foreach(_global.actors, function(k, a)
    if a.control.current == "dead" then table.insert(terminate, k) end
  end)
  table.foreach(terminate, function(k, v)
    _global.actors[v] = nil
  end)
  if rats <= 0 and not finishtime then finishtime = love.timer.getTime() end
  if love.keyboard.isDown("escape") then love.event.quit() end
end

function love.draw()
  local s = 3
  love.graphics.scale(s)
  if not finishtime then
    love.graphics.setBackgroundColor(115, 186, 200, 200)
      -- HACK, replace with actual love window dim API
    local w = 800
    local h = 600
    -- end-of-HACK
    local ie = _global.actors.main.context.entity
    local map = _global.map
    local mapwidth = map.width * map.tilewidth
    local mapheight = map.height * map.tileheight

    local x = math.min(map.x + mapwidth - w / s, math.max(-map.x, ie.x - 0.5 * w / s))
    local y = math.max(map.y - mapheight + h / s, math.min(map.y, ie.y + 0.5 * h / s))
    love.graphics.translate(-x, y)
    -- Render actors
    --love.graphics.scale(1, -1)
    _global.map:draw()
    love.graphics.scale(1, -1)

    table.foreach(_global.actors,
      function(_, a)
        actor.draw(a)
      end
    )
    love.graphics.origin()
    love.graphics.scale(s)
    love.graphics.print("Rats: " .. tostring(rats), 200, 10)
    if love.keyboard.isDown("t") then
      love.graphics.print(love.timer.getTime() - _global.time, 200, 30)
    end
  else
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.print("You are the best!", 50, 70)
    love.graphics.print("Time = " .. finishtime - _global.time .. "s", 50, 100)
    love.graphics.print("Thank you for playing :)", 50, 130)
  end
end
