-- Clipboard history with chooser UI

local history = {}
local maxHistory = 50
local lastChange = hs.pasteboard.changeCount()

-- Poll for clipboard changes
local clipWatcher = hs.timer.new(0.5, function()
  local currentChange = hs.pasteboard.changeCount()
  if currentChange == lastChange then return end
  lastChange = currentChange

  local content = hs.pasteboard.getContents()
  if not content or content == "" then return end

  -- Remove duplicate if already in history
  for i, item in ipairs(history) do
    if item == content then
      table.remove(history, i)
      break
    end
  end

  -- Add to front
  table.insert(history, 1, content)

  -- Trim to max size
  while #history > maxHistory do
    table.remove(history)
  end
end)

clipWatcher:start()

-- Show clipboard history chooser
local function showClipboard()
  local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    hs.pasteboard.setContents(choice.text)
    hs.eventtap.keyStroke("cmd", "v")
  end)

  local choices = {}
  for i, item in ipairs(history) do
    -- Truncate display text for long entries
    local display = item:gsub("\n", "⏎ ")
    if #display > 100 then
      display = display:sub(1, 100) .. "…"
    end
    table.insert(choices, {
      text = item,
      subText = display,
    })
  end

  chooser:choices(choices)
  chooser:placeholderText("Search clipboard history…")
  chooser:show()
end

local M = {}

M.show = showClipboard

return M
