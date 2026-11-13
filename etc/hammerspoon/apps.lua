-- App hotkeys: bring an app's last active window forward, launch it if needed.
-- The same key again, from that app, goes back to the window we came from.
local M = {}

-- Topmost window of another app: the way back when ours was closed.
local function other(bundleID)
  return hs.fnutils.find(hs.window.orderedWindows(), function(w)
    local app = w:application()
    return app and app:bundleID() ~= bundleID
  end)
end

function M.focus(bundleID)
  local back
  return function()
    local front = hs.application.frontmostApplication()
    if front and front:bundleID() == bundleID then
      local w = back and back:id() and hs.window.get(back:id()) or other(bundleID)
      back = nil
      if w then w:focus() end
      return
    end
    back = hs.window.focusedWindow()
    local app = hs.application.get(bundleID)
    if not app then return hs.application.launchOrFocusByBundleID(bundleID) end
    local win = app:mainWindow() or app:allWindows()[1]
    if not win then return app:activate() end
    if win:isMinimized() then win:unminimize() end
    win:focus()
  end
end

return M
