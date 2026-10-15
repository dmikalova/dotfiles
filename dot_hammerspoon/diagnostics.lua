-- Diagnostics for hotkey delivery failures.
--
-- Symptom this exists for: every alt-hotkey stops working while Hammerspoon
-- itself stays healthy (IPC responds, window:focus() works when called
-- directly). The Lua side looks fine - hs.hotkey.getHotkeys() reports every
-- binding enabled - because the break is in macOS delivering the Carbon
-- hotkey event, not in the callback. Only hs.reload() clears it.
--
-- To tell the two apart you need to know whether the callback ran at all.
-- This module records every callback invocation, and separately watches the
-- raw key events, so a keypress that arrives as an event but never reaches a
-- callback is logged as a stall.
--
-- Usage from the console or `hs -c`:
--   diagnostics.dump()         -- snapshot of hotkey/window/space state
--   diagnostics.tail(40)       -- recent log lines
--   diagnostics.logPath        -- ~/.hammerspoon/diagnostics.log

local M = {}

M.logPath = os.getenv("HOME") .. "/.hammerspoon/diagnostics.log"

local MAX_LOG_BYTES = 256 * 1024
local STALL_TIMEOUT = 0.3
local STALL_NOTIFY_INTERVAL = 60

local boundKeys = {}
local pendingStalls = {}
local lastStallNotify = 0

local function rotate()
  local attrs = hs.fs.attributes(M.logPath)
  if attrs and attrs.size and attrs.size > MAX_LOG_BYTES then
    os.rename(M.logPath, M.logPath .. ".1")
  end
end

local function log(fmt, ...)
  rotate()
  local f = io.open(M.logPath, "a")
  if not f then return end
  f:write(os.date("%Y-%m-%d %H:%M:%S ") .. string.format(fmt, ...) .. "\n")
  f:close()
end
M.log = log

-- Canonical label for a chord, so bindings and raw key events can be compared
local function label(mods, key)
  local names = {}
  if type(mods) == "string" then
    for m in mods:gmatch("%a+") do names[#names + 1] = m:lower() end
  else
    for _, m in ipairs(mods or {}) do names[#names + 1] = tostring(m):lower() end
  end
  table.sort(names)
  return table.concat(names, "+") .. "+" .. tostring(key):lower()
end

local function recordFire(chord)
  local n = pendingStalls[chord]
  if n and n > 0 then
    pendingStalls[chord] = n - 1
  end
  log("fire %s", chord)
end

-- Instrument hs.hotkey.bind so every binding made after this module loads
-- reports its invocations and its errors.
local rawBind = hs.hotkey.bind
hs.hotkey.bind = function(mods, key, ...)
  local chord = label(mods, key)
  boundKeys[chord] = true

  local args = table.pack(...)
  for i = 1, args.n do
    if type(args[i]) == "function" then
      local fn = args[i]
      args[i] = function(...)
        recordFire(chord)
        local ok, err = xpcall(fn, debug.traceback, ...)
        if not ok then
          log("ERROR %s: %s", chord, tostring(err))
        end
      end
      break
    end
  end

  return rawBind(mods, key, table.unpack(args, 1, args.n))
end

local function notifyStall(chord)
  local now = os.time()
  if now - lastStallNotify < STALL_NOTIFY_INTERVAL then return end
  lastStallNotify = now
  hs.notify.new({
    title = "Hammerspoon hotkeys stalled",
    informativeText = chord .. " was not delivered. Press alt+H to reload.",
  }):send()
end

-- Watch raw key events for chords we bound. If the event arrives but no
-- callback runs, macOS stopped delivering the Carbon hotkey.
local watcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  local flags = e:getFlags()
  if not flags.alt then return false end

  local key = hs.keycodes.map[e:getKeyCode()]
  if not key then return false end

  local mods = {}
  for _, m in ipairs({ "cmd", "ctrl", "alt", "shift" }) do
    if flags[m] then mods[#mods + 1] = m end
  end

  local chord = label(mods, key)
  if not boundKeys[chord] then return false end

  pendingStalls[chord] = (pendingStalls[chord] or 0) + 1
  hs.timer.doAfter(STALL_TIMEOUT, function()
    local n = pendingStalls[chord]
    if n and n > 0 then
      pendingStalls[chord] = n - 1
      log("STALL %s: key event seen, callback never ran", chord)
      notifyStall(chord)
    end
  end)

  return false
end)
watcher:start()

-- macOS disables an event tap that blocks for too long; restart it if so.
local watcherKeepalive = hs.timer.new(30, function()
  if not watcher:isEnabled() then
    log("WARN key watcher was disabled by the system, restarting")
    watcher:start()
  end
end)
watcherKeepalive:start()

function M.dump()
  local out = {}
  local function add(fmt, ...) out[#out + 1] = string.format(fmt, ...) end

  add("accessibility=%s", tostring(hs.accessibilityState()))
  -- When true, macOS suppresses every event tap and synthetic keystroke
  -- system-wide. Nothing in this config can work until it clears.
  add("secureInput=%s", tostring(hs.eventtap.isSecureInputEnabled()))
  add("keyWatcherEnabled=%s", tostring(watcher:isEnabled()))

  local disabled = {}
  local total = 0
  for _, h in ipairs(hs.hotkey.getHotkeys()) do
    total = total + 1
    if not h.enabled then disabled[#disabled + 1] = tostring(h.msg) end
  end
  add("hotkeys=%d disabled=%s", total, #disabled > 0 and table.concat(disabled, ",") or "none")

  local active = {}
  for _, spaceId in pairs(hs.spaces.activeSpaces()) do active[#active + 1] = tostring(spaceId) end
  add("focusedSpace=%s activeSpaces=%s", tostring(hs.spaces.focusedSpace()), table.concat(active, ","))

  local screenSpaces = {}
  for _, s in ipairs(hs.spaces.spacesForScreen(hs.screen.mainScreen()) or {}) do
    screenSpaces[#screenSpaces + 1] = tostring(s)
  end
  add("mainScreenSpaces=%s", table.concat(screenSpaces, ","))

  local wins = hs.window.allWindows()
  add("windows=%d", #wins)
  for _, w in ipairs(wins) do
    local app = w:application()
    local spaces = hs.spaces.windowSpaces(w) or {}
    local ids = {}
    for _, s in ipairs(spaces) do ids[#ids + 1] = tostring(s) end
    add("  %s id=%s spaces=%s visible=%s",
      app and app:name() or "?", tostring(w:id()),
      table.concat(ids, "/"), tostring(w:isVisible()))
  end

  local focused = hs.window.focusedWindow()
  local focusedApp = focused and focused:application()
  add("focused=%s id=%s",
    focusedApp and focusedApp:name() or "none",
    tostring(focused and focused:id()))

  local pending = {}
  for chord, n in pairs(pendingStalls) do
    if n > 0 then pending[#pending + 1] = chord .. "=" .. n end
  end
  add("pendingStalls=%s", #pending > 0 and table.concat(pending, ",") or "none")

  return table.concat(out, "\n")
end

function M.tail(lines)
  lines = lines or 20
  local output = hs.execute("tail -n " .. tonumber(lines) .. " " .. M.logPath)
  return output or ""
end

log("--- diagnostics loaded ---")

_G.diagnostics = M
return M
