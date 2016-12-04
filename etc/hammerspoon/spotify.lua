require 'libzen'
local log = hs.logger.new('riptide.spotify', 'debug')


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

local function playerControls()
end

local menuIcon = hs.menubar.new()
  :setIcon(getIcon('media-play-outline', 16))
  :setClickCallback(playerControls)
