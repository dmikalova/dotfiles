-- App switching functionality

-- To list all window names in the Hammerspoon console:
-- for _, w in ipairs(hs.window.filter.new(true):getWindows()) do print(w:application():name() .. " | " .. (w:title() or "")) end

-- App shortcuts configuration
-- Types: "work", "personal", "any", "both", "space-args", "reserved"
--   work/personal: launch in designated space (work=left, personal=right)
--   any: switch to app regardless of current space
--   both: opens new instance if no window on current space
--   space-args: like "both", but launches with space-specific args (4th element)
--   reserved: key used elsewhere (noop)

local messagesPWABundleID = "com.google.Chrome.app.hpfldicfbfomlpcikngkocigghgafkph"
local apps = {
  { "B", "Bitwarden",          "personal" },
  { "C", "Google Chrome",      "space-args", { work = '--profile-directory="Profile 1"', personal = '--profile-directory="Default"' } },
  { "D", "Finder",             "reserved" },
  { "G", "Signal",             "personal" },
  { "H", "Hammerspoon Reload", "reserved" },
  { "I", "Discord",            "personal" },
  { "K", "Slack",              "work" },
  { "M", messagesPWABundleID,  "personal" },
  { "O", "Obsidian",           "personal" },
  { "P", "LastPass",           "work" },
  { "S", "System Settings",    "any" },
  { "T", "Warp",               "both" },
  { "V", "Code",               "both" },
  { "Y", "YouTube Music",      "personal" },
  { "X", "Clipboard",          "reserved" },
  { "Z", "zoom.us",            "any" },
}

-- Enable Spotlight for finding apps by name (needed for VS Code, etc.)
hs.application.enableSpotlightForNameSearches(true)

-- Check if identifier looks like a bundle ID (contains multiple dots)
local function isBundleID(identifier)
  local _, count = string.gsub(identifier, "%.", "")
  return count >= 2
end

-- Launch or focus app by name or bundle ID
local function launchOrFocusApp(identifier)
  if isBundleID(identifier) then
    hs.application.launchOrFocusByBundleID(identifier)
  else
    hs.application.launchOrFocus(identifier)
  end
end

-- Find app by name or bundle ID
local function findApp(identifier)
  return hs.application.find(identifier)
end

-- Match window's app against identifier (name or bundle ID)
local function appMatches(winApp, identifier)
  if not winApp then return false end
  if isBundleID(identifier) then
    return winApp:bundleID() == identifier
  else
    return winApp:name() == identifier
  end
end

-- Get all spaces for the main screen
local function getAllSpaces()
  return hs.spaces.spacesForScreen(hs.screen.mainScreen())
end

-- Get the space ID for work (first/left) or personal (second/right)
local function getSpaceForType(spaceType)
  local spaces = getAllSpaces()
  if spaceType == "work" then
    return spaces[1]
  elseif spaceType == "personal" then
    return spaces[2]
  end
  return nil
end

-- Get index of a space (1-based)
local function getSpaceIndex(targetSpace)
  for i, space in ipairs(getAllSpaces()) do
    if space == targetSpace then
      return i
    end
  end
  return nil
end

-- Send Ctrl+Arrow keystroke for space switching
local function sendCtrlArrow(arrowKey)
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
  hs.eventtap.event.newKeyEvent(arrowKey, true):post()
  hs.eventtap.event.newKeyEvent(arrowKey, false):post()
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end

-- Switch spaces using Ctrl+Arrow for smooth slide animation
local function gotoSpaceSmooth(targetSpace)
  local currentIndex = getSpaceIndex(hs.spaces.focusedSpace())
  local targetIndex = getSpaceIndex(targetSpace)

  if not targetIndex or targetIndex == currentIndex then
    return
  end

  local arrowKey = targetIndex < currentIndex and "left" or "right"
  local steps = math.abs(targetIndex - currentIndex)

  for i = 1, steps do
    sendCtrlArrow(arrowKey)
  end
end

-- Get windows of an app that are on the current space
local function getWindowsOnCurrentSpace(app)
  local currentSpace = hs.spaces.focusedSpace()
  local windowsOnSpace = {}

  -- Use global search (needed for Electron apps like VS Code, Warp)
  for _, win in ipairs(hs.window.allWindows()) do
    local winApp = win:application()
    if appMatches(winApp, app) then
      local winSpaces = hs.spaces.windowSpaces(win)
      if winSpaces then
        for _, spaceId in ipairs(winSpaces) do
          if spaceId == currentSpace then
            table.insert(windowsOnSpace, win)
            break
          end
        end
      end
    end
  end
  return windowsOnSpace
end

-- Launch, focus, or rotate through windows of an app (all spaces)
local function launchOrFocusOrRotate(app)
  local appWindows = {}
  for _, win in ipairs(hs.window.allWindows()) do
    if appMatches(win:application(), app) then
      table.insert(appWindows, win)
    end
  end

  if #appWindows == 0 then
    launchOrFocusApp(app)
    return
  end

  -- First in list is most recently used (hs.window.allWindows() is MRU-ordered)
  local mruWindow = appWindows[1]

  -- Sort by window ID for stable rotation order
  table.sort(appWindows, function(a, b) return a:id() < b:id() end)

  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow and #appWindows > 1 then
    for i, win in ipairs(appWindows) do
      if win:id() == focusedWindow:id() then
        local nextIndex = (i % #appWindows) + 1
        appWindows[nextIndex]:focus()
        return
      end
    end
  end
  -- Switching to app from another app: focus most recently used window
  mruWindow:focus()
end

-- Click-drag a window to another space
local function moveWindowToSpaceByDrag(win, appObj, moveLeft)
  local frame = win:frame()
  if not frame then return end

  local clickPoint = { x = frame.x + 55, y = frame.y + 4 }
  local originalMousePos = hs.mouse.absolutePosition()

  hs.mouse.absolutePosition(clickPoint)
  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPoint):post()

  hs.timer.usleep(20000)
  sendCtrlArrow(moveLeft and "left" or "right")
  hs.timer.usleep(20000)

  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPoint):post()
  hs.mouse.absolutePosition(originalMousePos)
end

-- Launch app in a specific space, or focus if already running
-- If app is in wrong space, move it to correct space
local function launchOrFocusInSpace(app, spaceType)
  local targetSpace = getSpaceForType(spaceType)
  local startSpace = hs.spaces.focusedSpace()

  local appObj = findApp(app)

  if not appObj then
    -- App not running: go to target space first, then launch
    if targetSpace and startSpace ~= targetSpace then
      gotoSpaceSmooth(targetSpace)
    end
    launchOrFocusApp(app)
    return
  end

  -- App is running - use launchOrFocus to switch to its window
  launchOrFocusApp(app)
  hs.timer.usleep(300000)

  -- Now we should be on the space with the window - find it
  local win = nil
  local wins = appObj:allWindows()
  if #wins > 0 then
    win = wins[1]
  end

  -- Fallback to global search
  if not win then
    for _, w in ipairs(hs.window.allWindows()) do
      local wApp = w:application()
      if appMatches(wApp, app) then
        win = w
        break
      end
    end
  end

  if not win then return end

  -- Check if window is in correct space
  local currentSpace = hs.spaces.focusedSpace()

  local winSpaces = hs.spaces.windowSpaces(win)
  local currentWinSpace = winSpaces and winSpaces[1]

  if currentWinSpace == targetSpace or not targetSpace then
    -- Window already in correct space, just switch and focus
    if targetSpace and currentSpace ~= targetSpace then
      gotoSpaceSmooth(targetSpace)
    end
    win:focus()
    if appObj then appObj:activate() end
    return
  end

  -- Window in wrong space - need to move it
  local moveLeft = getSpaceIndex(targetSpace) < getSpaceIndex(currentWinSpace)

  if currentSpace ~= currentWinSpace then
    gotoSpaceSmooth(currentWinSpace)
    hs.timer.usleep(300000)
  end
  win:focus()
  if appObj then appObj:activate() end
  if appObj then
    moveWindowToSpaceByDrag(win, appObj, moveLeft)
  end
end

-- Launch, focus, or rotate - but only consider windows on current space
-- Opens new instance if no windows on current space
local function launchOrFocusOrRotateCurrentSpace(app)
  local windowsOnSpace = getWindowsOnCurrentSpace(app)

  if #windowsOnSpace == 0 then
    -- No windows on current space, open new instance
    if isBundleID(app) then
      hs.application.launchOrFocusByBundleID(app)
    else
      hs.execute('open -n -a "' .. app .. '"')
    end
    return
  end

  -- First in list is most recently used (hs.window.allWindows() is MRU-ordered)
  local mruWindow = windowsOnSpace[1]

  -- Sort by window ID for stable rotation order
  table.sort(windowsOnSpace, function(a, b) return a:id() < b:id() end)

  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow and #windowsOnSpace > 1 then
    -- Find current window index and rotate to next
    for i, win in ipairs(windowsOnSpace) do
      if win:id() == focusedWindow:id() then
        local nextIndex = (i % #windowsOnSpace) + 1
        windowsOnSpace[nextIndex]:focus()
        return
      end
    end
  end
  -- Switching to app from another app: focus most recently used window
  mruWindow:focus()
end

-- Bind all apps based on their type
for _, shortcut in ipairs(apps) do
  local key, app, appType = shortcut[1], shortcut[2], shortcut[3]
  if appType == "reserved" then
    -- noop - key used elsewhere
  elseif appType == "both" then
    hs.hotkey.bind("alt", key, function()
      launchOrFocusOrRotateCurrentSpace(app)
    end)
  elseif appType == "space-args" then
    local spaceArgs = shortcut[4]
    hs.hotkey.bind("alt", key, function()
      local windowsOnSpace = getWindowsOnCurrentSpace(app)

      if #windowsOnSpace == 0 then
        local currentSpace = hs.spaces.focusedSpace()
        local workSpace = getSpaceForType("work")
        local args = (currentSpace == workSpace) and spaceArgs.work or spaceArgs.personal
        hs.execute('open -n -a "' .. app .. '" --args ' .. args)
        return
      end

      local mruWindow = windowsOnSpace[1]
      table.sort(windowsOnSpace, function(a, b) return a:id() < b:id() end)

      local focusedWindow = hs.window.focusedWindow()
      if focusedWindow and #windowsOnSpace > 1 then
        for i, win in ipairs(windowsOnSpace) do
          if win:id() == focusedWindow:id() then
            local nextIndex = (i % #windowsOnSpace) + 1
            windowsOnSpace[nextIndex]:focus()
            return
          end
        end
      end
      mruWindow:focus()
    end)
  elseif appType == "work" or appType == "personal" then
    hs.hotkey.bind("alt", key, function()
      launchOrFocusInSpace(app, appType)
    end)
  elseif appType == "any" then
    hs.hotkey.bind("alt", key, function()
      launchOrFocusOrRotate(app)
    end)
  end
end

-- Alt+D: Finder - focus window on current space or open new window
hs.hotkey.bind("alt", "D", function()
  local windowsOnSpace = getWindowsOnCurrentSpace("Finder")

  if #windowsOnSpace == 0 then
    -- No Finder window on current space, open new one
    hs.osascript.applescript('tell application "Finder" to make new Finder window')
    hs.application.launchOrFocus("Finder")
    return
  end

  local mruWindow = windowsOnSpace[1]
  table.sort(windowsOnSpace, function(a, b) return a:id() < b:id() end)

  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow and #windowsOnSpace > 1 then
    for i, win in ipairs(windowsOnSpace) do
      if win:id() == focusedWindow:id() then
        local nextIndex = (i % #windowsOnSpace) + 1
        windowsOnSpace[nextIndex]:focus()
        return
      end
    end
  end
  mruWindow:focus()
end)
