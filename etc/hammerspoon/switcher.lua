-- Windows-style switcher (was BetterTouchTool): ⌥⇥ next, ⌥⇧⇥ back.
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
M.keys = {
  hs.hotkey.bind({'alt'}, 'tab', fwd, nil, fwd),
  hs.hotkey.bind({'alt', 'shift'}, 'tab', prev, nil, prev),
}

return M
