-- Media keys: never let Play/Pause open Apple Music
--
-- If YouTube Music is running, pass Play/Pause through to it. Otherwise
-- absorb the key (so macOS does not open Apple Music) and open YouTube Music.

local M = {}

local youtubeMusic = "YouTube Music"

-- Decided on key down and reused for the matching key up
local absorbing = false

local tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(e)
  local key = e:systemKey()
  if key.key ~= "PLAY" then return false end

  if key.down and not key["repeat"] then
    absorbing = hs.application.get(youtubeMusic) == nil
    if absorbing then hs.application.launchOrFocus(youtubeMusic) end
  end
  return absorbing
end)
tap:start()

-- macOS disables an event tap that blocks for too long; restart it if so.
local keepalive = hs.timer.new(30, function()
  if not tap:isEnabled() then tap:start() end
end)
keepalive:start()

-- Returned so require() keeps the tap referenced (not garbage collected)
M.tap = tap
M.keepalive = keepalive

return M
