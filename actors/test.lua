require "actor"

local keybuffer = {
  [" "] = 0.3
}

local function pressed(f, k)
  local t = f.keyboard[k] or -1e300
  local buffer = keybuffer[k] or 0.1
  return love.timer.getTime() - t < buffer
end

local test = actor.new()

-- Right state
local rightstate = "right"
test.visual[rightstate] = function(c)
  love.graphics.print("right", 0, -100, 0, 1, -1)
end

-- Left state
local leftstate = "left"
test.visual[leftstate] = function(c)
  love.graphics.print("left", 0, -100, 0, 1, -1)
end

-- Edges
fsm.connect(test.control, rightstate).to(leftstate).when(
  function(c, f)
    if pressed(f, "left") then return 1 end
  end
)
fsm.connect(test.control, leftstate).to(rightstate).when(
  function(c, f)
    if pressed(f, "right") then return 1 end
  end
)

-- Init
test.control.current = rightstate

return test
