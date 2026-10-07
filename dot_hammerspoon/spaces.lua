-- Space navigation and window moving

-- Send Ctrl+Arrow keystroke for space switching. Flags are set explicitly on
-- every event: without a mods table, Hammerspoon derives flags from a single
-- private CGEventSource that lives until reload, so if its tracked modifier
-- state drifts the arrow goes out with the wrong modifiers and macOS ignores
-- it until hs.reload() recreates the source. Arrow keys carry fn natively.
local function sendCtrlArrow(direction)
  hs.eventtap.event.newKeyEvent({ "ctrl" }, "ctrl", true):post()
  hs.eventtap.event.newKeyEvent({ "ctrl", "fn" }, direction, true):post()
  hs.eventtap.event.newKeyEvent({ "ctrl", "fn" }, direction, false):post()
  hs.eventtap.event.newKeyEvent({}, "ctrl", false):post()
end

-- Move focused window to adjacent space using click-drag
local function moveWindowToAdjacentSpace(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local frame = win:frame()
  if not frame then return end

  -- Click near traffic light buttons (above yellow fullscreen button)
  local clickPoint = { x = frame.x + 55, y = frame.y + 4 }
  local originalMousePos = hs.mouse.absolutePosition()

  hs.mouse.absolutePosition(clickPoint)
  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPoint):post()

  hs.timer.usleep(20000)
  sendCtrlArrow(direction)
  hs.timer.usleep(20000)

  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPoint):post()
  hs.mouse.absolutePosition(originalMousePos)

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
