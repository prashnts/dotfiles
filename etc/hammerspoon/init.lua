

--
-- Bring all Finder windows forward when one gets activated
function finderActivationHandler(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      appObject:selectMenuItem({"Window", "Bring All to Front"})
    end
  end
end
local appWatcher = hs.application.watcher.new(finderActivationHandler)
appWatcher:start()


-- Show current network usage in Menu Bar.
-- local ifstats = hs.menubar.new()
-- function setIfstatValue(state)
--   ifstats:setTitle(state)
-- end

-- function ifstatsClickHandler()
--   setIfstatValue("↓")
-- end

-- if ifstats then
--   ifstats:setClickCallback(ifstatsClickHandler)
--   setIfstatValue("↑")
-- end


-- Mute spotify if there's an Ad. Yeah...
function muteSpotifyOnAd()
  if (hs.spotify.isRunning()) then
    if (hs.spotify.getCurrentTrack():lower() == 'spotify') then
      hs.spotify.setVolume(0)
    else
      hs.spotify.setVolume(100)
    end
  end
end
hs.timer.doEvery(10, muteSpotifyOnAd)


-- Alternative iTerm2 hotkey
function iTermHotkeyHandler()
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
