-- Window positioning and resizing
hs.window.animationDuration = 0.001

local mod = { "ctrl", "alt" }

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
  -- Corners (30% × 50%)
  --   Q W
  --   Z X
  Q = { 0, 0, 0.3, 0.5 },     -- Top left
  W = { 0.7, 0, 0.3, 0.5 },   -- Top right
  Z = { 0, 0.5, 0.3, 0.5 },   -- Bottom left
  X = { 0.7, 0.5, 0.3, 0.5 }, -- Bottom right

  -- Sides (30% width, full height)
  --   A   S
  A = { 0, 0, 0.3, 1 },   -- Left
  S = { 0.7, 0, 0.3, 1 }, -- Right

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
