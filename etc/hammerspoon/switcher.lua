-- Windows-style switcher (was BetterTouchTool): ⌘⇥ next, ⌘⇧⇥ back,
-- in place of the macOS app switcher.
-- Windows, not apps, most recently focused first (mouse or keyboard); a tap
-- goes back to the last window, same app or not. When an app raises all its
-- windows, only the one that got focus moves up. No thumbnails: those need
-- Screen Recording.
local M = {}
local wf = hs.window.filter

-- Focus order is only recorded while a filter is active: keep this one
-- subscribed, otherwise focus changes between two ⌥⇥ go unseen.
M.filter = wf.new():setCurrentSpace(true):setDefaultFilter{}
  :subscribe(wf.windowFocused, function() end)

M.switcher = hs.window.switcher.new(M.filter,
  {showThumbnails = false, showSelectedThumbnail = false, textSize = 14})

local function fwd() M.switcher:next() end
local function prev() M.switcher:previous() end
-- macOS keeps ⌘⇥ from hotkeys, so take it in an event tap (Accessibility).
local TAB = hs.keycodes.map.tab
M.tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if e:getKeyCode() ~= TAB then return false end
  local f = e:getFlags()
  if not f.cmd or f.alt or f.ctrl then return false end
  if f.shift then prev() else fwd() end
  return true
end):start()

-- macOS disables a tap that once answered too slowly: switch it back on.
M.watchdog = hs.timer.doEvery(5, function()
  if not M.tap:isEnabled() then M.tap:start() end
end)

return M
