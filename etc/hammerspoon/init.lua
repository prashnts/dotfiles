require 'libzen'
require 'iTerm2'

local log = hs.logger.new('riptide', 'debug')
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
local _spotifyWasMuted
local function muteSpotifyOnAd()
  if hs.spotify.isPlaying() then
    if hs.spotify.getCurrentTrack():lower():has('spotify') then
      _spotifyWasMuted = true
      hs.audiodevice.defaultOutputDevice():setMuted(true)
    elseif _spotifyWasMuted then
      _spotifyWasMuted = false
      hs.audiodevice.defaultOutputDevice():setMuted(false)
    end
  end
end
local spotify = hs.timer.new(5, muteSpotifyOnAd, true)
spotify:start()

