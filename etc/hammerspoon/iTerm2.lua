-- === iTerm2 Bindings ===
--
-- Alternative iTerm2 hotkey
local function iTermHotkeyHandler()
  local iterm = hs.application.get('iTerm2')
  if (iterm) then
    local window = iterm:mainWindow()
    if not window then
      if iterm:selectMenuItem('New Window') then
        window = iterm:mainWindow()
      end
      return
    end
    if iterm:isFrontmost() then
      iterm:hide()
    else
      window:focus()
    end
  end
end

hs.hotkey.bind('cmd', 'space', iTermHotkeyHandler)
