-- Window positioning and resizing
hs.window.animationDuration = 0.001

local mod = { "ctrl", "alt" }

-- Screens at/above this width (in points) get the "large" side-split (30/40/30,
-- tuned for a 52" ultrawide). Everything smaller (laptop screen, external
-- monitors) gets a 50/50 half-split instead.
local LARGE_SCREEN_WIDTH_THRESHOLD = 3000

local function isLargeScreen(win)
  return win:screen():frame().w >= LARGE_SCREEN_WIDTH_THRESHOLD
end

-- Helper: move window to position (percentages of screen)
local function moveWindow(x, y, w, h)
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local frame = screen:frame()

  win:setFrame({
    x = frame.x + (frame.w * x),
    y = frame.y + (frame.h * y),
    w = frame.w * w,
    h = frame.h * h,
  })
end

-- Helper: resize window edges by 10% increments
local function resizeWindow(leftDelta, rightDelta)
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen()
  local screenFrame = screen:frame()
  local winFrame = win:frame()

  local step = screenFrame.w * 0.1
  local newX = winFrame.x + (leftDelta * step)
  local newW = winFrame.w - (leftDelta * step) + (rightDelta * step)

  -- Clamp to screen bounds
  if newX < screenFrame.x then newX = screenFrame.x end
  if newW < step then newW = step end
  if newX + newW > screenFrame.x + screenFrame.w then
    newW = screenFrame.x + screenFrame.w - newX
  end

  win:setFrame({ x = newX, y = winFrame.y, w = newW, h = winFrame.h })
end

-- Position presets: { x, y, w, h }
-- Keyboard layout mirrors position on screen
local positions = {
  -- Corners (50% × 50%)
  --   Q W
  --   Z X
  Q = { 0, 0, 0.5, 0.5 },     -- Top left
  W = { 0.5, 0, 0.5, 0.5 },   -- Top right
  Z = { 0, 0.5, 0.5, 0.5 },   -- Bottom left
  X = { 0.5, 0.5, 0.5, 0.5 }, -- Bottom right

  -- Width presets (full height)
  --   Y U I  (70%, 40%, 70%)
  --   H J K  (80%, 60%, 80%)
  Y = { 0, 0, 0.7, 1 },   -- Left-aligned 70%
  U = { 0.3, 0, 0.4, 1 }, -- Centered 40%
  I = { 0.3, 0, 0.7, 1 }, -- Right-aligned 70%
  H = { 0, 0, 0.8, 1 },   -- Left-aligned 80%
  J = { 0.2, 0, 0.6, 1 }, -- Centered 60%
  K = { 0.2, 0, 0.8, 1 }, -- Right-aligned 80%

  -- Maximize
  M = { 0, 0, 1, 1 },
}

for key, pos in pairs(positions) do
  hs.hotkey.bind(mod, key, function()
    moveWindow(pos[1], pos[2], pos[3], pos[4])
  end)
end

-- Sides (A left, S right): 30% width on large screens (paired with U's centered
-- 40% for a 30/40/30 split), 50% width (halves) on smaller screens.
local largeSides = { A = { 0, 0, 0.3, 1 }, S = { 0.7, 0, 0.3, 1 } }
local smallSides = { A = { 0, 0, 0.5, 1 }, S = { 0.5, 0, 0.5, 1 } }

for _, key in ipairs({ "A", "S" }) do
  hs.hotkey.bind(mod, key, function()
    local win = hs.window.focusedWindow()
    if not win then return end

    local sides = isLargeScreen(win) and largeSides or smallSides
    local pos = sides[key]
    moveWindow(pos[1], pos[2], pos[3], pos[4])
  end)
end

-- Resize by 10% increments
-- EDC = shrink, RFV = expand
--   E R  (left edge)
--   D F  (both edges)
--   C V  (right edge)
local resizes = {
  E = { 1, 0 },  -- Shrink left
  R = { -1, 0 }, -- Expand left
  D = { 1, -1 }, -- Shrink both
  F = { -1, 1 }, -- Expand both
  C = { 0, -1 }, -- Shrink right
  V = { 0, 1 },  -- Expand right
}

for key, delta in pairs(resizes) do
  hs.hotkey.bind(mod, key, function()
    resizeWindow(delta[1], delta[2])
  end)
end

-- Find the screen immediately west/east of the given screen, by sorting all
-- screens left-to-right. Returns nil at either end (idempotent: repeatedly
-- throwing past the last screen in a direction does nothing).
-- (hs.screen:toWest()/toEast() use an angle-based heuristic that can behave
-- asymmetrically when screens aren't vertically aligned, so we sort explicitly.)
local function adjacentScreen(win, direction)
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)

  local currentId = win:screen():id()
  local index = nil
  for i, s in ipairs(screens) do
    if s:id() == currentId then
      index = i
      break
    end
  end
  if not index then return nil end

  local targetIndex = direction == "west" and (index - 1) or (index + 1)
  return screens[targetIndex]
end

-- Throw focused window to the adjacent screen, preserving its relative
-- position/size. M = west (left of the space-move ","), / = east (right of ".").
local function throwToScreen(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local target = adjacentScreen(win, direction)
  if not target then return end

  win:moveToScreen(target, false, true)
end

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "M", function() throwToScreen("west") end)
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "/", function() throwToScreen("east") end)
