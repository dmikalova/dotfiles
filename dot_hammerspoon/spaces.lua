-- Space navigation and window moving

local input = require("input")
local sendCtrlArrow = input.sendCtrlArrow

-- Move focused window to adjacent space using click-drag
local function moveWindowToAdjacentSpace(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local frame = win:frame()
  if not frame then return end

  -- Click near traffic light buttons (above yellow fullscreen button)
  local clickPoint = { x = frame.x + 55, y = frame.y + 4 }

  input.withLeftButtonHeld(clickPoint, function()
    hs.timer.usleep(20000)
    sendCtrlArrow(direction)
    hs.timer.usleep(20000)
  end)

  win:focus()
  local appObj = win:application()
  if appObj then appObj:activate() end
end

-- Ctrl+Alt+,/.: Switch to adjacent space
hs.hotkey.bind({ "ctrl", "alt" }, ",", function()
  sendCtrlArrow("left")
end)

hs.hotkey.bind({ "ctrl", "alt" }, ".", function()
  sendCtrlArrow("right")
end)

-- Ctrl+Alt+Shift+,/.: Move focused window to adjacent space
hs.hotkey.bind({ "ctrl", "alt", "shift" }, ",", function()
  moveWindowToAdjacentSpace("left")
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, ".", function()
  moveWindowToAdjacentSpace("right")
end)

-- Ctrl+Alt+/: Toggle Mission Control
hs.hotkey.bind({ "ctrl", "alt" }, "/", function()
  hs.spaces.toggleMissionControl()
end)
