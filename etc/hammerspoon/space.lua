-- hyper+space: one action per frontmost app, nothing elsewhere.
-- Browsers: toggle the dev tools (⌥⌘I); Safari needs Settings > Advanced >
-- "Show features for web developers".
local M = {}

local function devtools() hs.eventtap.keyStroke({'alt', 'cmd'}, 'i', 1000) end

M.actions = {}  -- bundle ID -> function
for _, id in ipairs({
  'com.apple.Safari', 'com.apple.SafariTechnologyPreview',
  'com.google.Chrome', 'com.google.Chrome.canary', 'org.chromium.Chromium',
  'com.brave.Browser', 'com.microsoft.edgemac', 'com.vivaldi.Vivaldi',
  'company.thebrowser.Browser',  -- Arc
  'org.mozilla.firefox', 'org.mozilla.firefoxdeveloperedition',
  'org.mozilla.nightly',
}) do M.actions[id] = devtools end

function M.run()
  local app = hs.application.frontmostApplication()
  local fn = app and M.actions[app:bundleID()]
  if fn then fn() end
end

return M
