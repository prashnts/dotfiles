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
local T = hs.eventtap.event.types
M.tap = hs.eventtap.new({T.keyDown}, function(e)
  if e:getKeyCode() ~= TAB then return false end
  local f = e:getFlags()
  if not f.cmd or f.alt or f.ctrl then return false end
  if f.shift then prev() else fwd() end
  return true
end)

-- A keyDown tap holds every key back while Hammerspoon is busy (the window
-- filter stalls on slow apps): run it only while ⌘ is down. The gate sees
-- modifier changes only, far fewer than keys.
local on = false
M.gate = hs.eventtap.new({T.flagsChanged}, function(e)
  local cmd = e:getFlags().cmd == true
  if cmd and not M.tap:isEnabled() then
    if on then print('switcher: ⌘⇥ tap timed out, Hammerspoon was busy') end
    M.tap:start()
  elseif not cmd and on then
    M.tap:stop()
  end
  on = cmd
  return false
end):start()

-- macOS disables a tap that once answered too slowly: switch it back on.
M.watchdog = hs.timer.doEvery(5, function()
  if not M.gate:isEnabled() then
    print('switcher: ⌘ gate timed out, Hammerspoon was busy')
    M.gate:start()
  end
end)

return M
