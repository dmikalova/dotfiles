-- Load modules
require("hs.ipc")
require("apps")
require("spaces")
require("windows")
local clipboard = require("clipboard")

-- Ctrl+H: Reload Hammerspoon config
hs.hotkey.bind("alt", "H", function()
  hs.reload()
end)

-- Alt+X: Close focused window
hs.hotkey.bind("alt", "X", function()
  local win = hs.window.focusedWindow()
  if win then win:close() end
end)

-- Cmd+Alt+L: Lock screen. hs.caffeinate.lockScreen() deadlocks the entire
-- Hammerspoon process on this machine (confirmed: it never returns, and even
-- IPC stops responding until force-quit). Simulate the native Lock Screen
-- shortcut instead, which goes through macOS's normal path.
hs.hotkey.bind({ "cmd", "alt" }, "L", function()
  hs.eventtap.keyStroke({ "ctrl", "cmd" }, "q")
end)

-- Cmd+Alt+V: Show clipboard history
hs.hotkey.bind({ "cmd", "alt" }, "V", clipboard.show)
