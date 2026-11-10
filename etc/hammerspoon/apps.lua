-- App hotkeys: bring an app's last active window forward, launch it if needed.
local M = {}

function M.focus(bundleID)
  return function()
    local app = hs.application.get(bundleID)
    if not app then return hs.application.launchOrFocusByBundleID(bundleID) end
    local win = app:mainWindow() or app:allWindows()[1]
    if not win then return app:activate() end
    if win:isMinimized() then win:unminimize() end
    win:focus()
  end
end

return M
