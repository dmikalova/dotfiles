-- Load modules
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

-- Cmd+Alt+L: Lock screen
hs.hotkey.bind({ "cmd", "alt" }, "L", function()
  hs.caffeinate.lockScreen()
end)

-- Cmd+Alt+V: Show clipboard history
hs.hotkey.bind({ "cmd", "alt" }, "V", clipboard.show)
