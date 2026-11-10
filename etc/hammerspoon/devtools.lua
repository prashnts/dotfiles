-- hyper+space: toggle the dev tools of the frontmost browser, or of the
-- topmost browser window when another app is in front. All use ⌥⌘I;
-- Safari needs Settings > Advanced > "Show features for web developers".
local M = {}

M.browsers = {
  ['com.apple.Safari'] = true,
  ['com.apple.SafariTechnologyPreview'] = true,
  ['com.google.Chrome'] = true,
  ['com.google.Chrome.canary'] = true,
  ['org.chromium.Chromium'] = true,
  ['com.brave.Browser'] = true,
  ['com.microsoft.edgemac'] = true,
  ['company.thebrowser.Browser'] = true,  -- Arc
  ['com.vivaldi.Vivaldi'] = true,
  ['org.mozilla.firefox'] = true,
  ['org.mozilla.firefoxdeveloperedition'] = true,
  ['org.mozilla.nightly'] = true,
}

local function isBrowser(app) return app and M.browsers[app:bundleID()] end

local function send() hs.eventtap.keyStroke({'alt', 'cmd'}, 'i', 1000) end

function M.toggle()
  if isBrowser(hs.application.frontmostApplication()) then return send() end
  local win = hs.fnutils.find(hs.window.orderedWindows(),
    function(w) return isBrowser(w:application()) end)
  if not win then return hs.alert.show('No browser', 0.5) end
  win:focus()
  hs.timer.doAfter(0.15, send)  -- let the focus land first
end

return M
