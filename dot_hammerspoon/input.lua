-- Synthetic input safety.
--
-- Every modifier down and mouse down posted here must have a matching up. If
-- one is lost - an error between the two calls, or a reload landing mid
-- sequence - macOS keeps that input latched in the window server's combined
-- session state. hs.reload() does not clear it, so the machine stays broken in
-- a way that looks like a hardware fault: a latched fn turns backspace into
-- forward delete, a latched ctrl swallows ordinary keys, and a latched left
-- button makes every click a drag.
--
-- releaseAll() clears that state. The helpers post their up events even when
-- the work between the down and the up fails.

local M = {}

-- capslock is deliberately absent: posting an up for it toggles the light.
local MODIFIERS = {
  "cmd", "alt", "ctrl", "shift", "fn",
  "rightcmd", "rightalt", "rightctrl", "rightshift",
}

local MOUSE_UP_TYPES = {
  hs.eventtap.event.types.leftMouseUp,
  hs.eventtap.event.types.rightMouseUp,
}

local NOTIFY_INTERVAL = 10
local lastNotify = 0

-- True when macOS Secure Input is active, which makes the window server drop
-- every synthetic event and every event tap. Carbon hotkeys still fire, so
-- without this check a binding runs, posts into the void and looks like a
-- Hammerspoon bug. A focused password field turns this on legitimately, so
-- treat it as a transient condition rather than an error.
--
-- Clear a stuck one by locking the screen and unlocking it by hand; if that
-- fails, log out. Find the holder with:
--   ioreg -l -w 0 | grep SecureInputPID
function M.postingBlocked(action)
  if not hs.eventtap.isSecureInputEnabled() then return false end

  local now = os.time()
  if now - lastNotify >= NOTIFY_INTERVAL then
    lastNotify = now
    hs.notify.new({
      title = "Secure input is active",
      informativeText = action .. " cannot run. Lock and unlock the screen to clear it.",
    }):send()
  end
  return true
end

-- Post an up event for every modifier and mouse button, whether or not it is
-- currently held. Safe to call at any time; an up for something already up is
-- ignored by the window server.
function M.releaseAll()
  for _, mod in ipairs(MODIFIERS) do
    hs.eventtap.event.newKeyEvent({}, mod, false):post()
  end

  local pos = hs.mouse.absolutePosition()
  for _, eventType in ipairs(MOUSE_UP_TYPES) do
    hs.eventtap.event.newMouseEvent(eventType, pos):post()
  end
end

-- Report anything still held, as a string, or nil when input is clean.
function M.stuck()
  local held = {}
  for mod, down in pairs(hs.eventtap.checkKeyboardModifiers() or {}) do
    if down == true and mod ~= "_raw" then held[#held + 1] = mod end
  end
  for _, button in ipairs(hs.eventtap.checkMouseButtons() or {}) do
    held[#held + 1] = "mouse" .. tostring(button)
  end
  if #held == 0 then return nil end
  table.sort(held)
  return table.concat(held, ",")
end

-- Send Ctrl+Arrow for space switching. Flags are set explicitly on every
-- event: without a mods table, Hammerspoon derives flags from a single private
-- CGEventSource that lives until reload, so if its tracked modifier state
-- drifts the arrow goes out with the wrong modifiers and macOS ignores it
-- until hs.reload() recreates the source. Arrow keys carry fn natively.
function M.sendCtrlArrow(direction)
  if M.postingBlocked("Switching spaces") then return false end

  hs.eventtap.event.newKeyEvent({ "ctrl" }, "ctrl", true):post()
  local ok, err = pcall(function()
    hs.eventtap.event.newKeyEvent({ "ctrl", "fn" }, direction, true):post()
    hs.eventtap.event.newKeyEvent({ "ctrl", "fn" }, direction, false):post()
  end)
  hs.eventtap.event.newKeyEvent({}, "ctrl", false):post()
  if not ok then error(err, 0) end
  return true
end

-- Run fn with the left mouse button held at point, then restore the cursor.
function M.withLeftButtonHeld(point, fn)
  if M.postingBlocked("Moving the window") then return false end

  local origin = hs.mouse.absolutePosition()
  hs.mouse.absolutePosition(point)
  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, point):post()

  local ok, err = pcall(fn)

  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, point):post()
  hs.mouse.absolutePosition(origin)
  if not ok then error(err, 0) end
  return true
end

return M
