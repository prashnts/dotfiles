local log = hs.logger.new('riptide.ddcci', 'debug')

local ddcctl = '/Users/prashantsinha/opt/bin/ddcctl'
local CMDFMT = '%s -d 1 -%s %s'

-- Use volume keys when external monitor is connected with ddc
BASE_VOLUME = 8
function syncVolume(volume)
  local cmd = CMDFMT:format(ddcctl, 'v', volume)
  log:d('sync volume with', cmd)
  hs.execute(cmd)
end

function volumeKeyUp()
  if BASE_VOLUME < 254 then
    BASE_VOLUME = BASE_VOLUME + 1
  end
  syncVolume(BASE_VOLUME)
end

function volumeKeyDown()
  if BASE_VOLUME > 1 then
    BASE_VOLUME = BASE_VOLUME - 1
  end
  syncVolume(BASE_VOLUME)
end

hs.hotkey.bind({"ctrl", "alt"}, "x", nil, volumeKeyUp, nil, nil)
hs.hotkey.bind({"ctrl", "alt"}, "z", nil, volumeKeyDown, nil, nil)

-- Sync main display brightness with external monitor
PREVIOUS_BRIGHTNESS = hs.brightness.get()
function syncMonitorBrightness()
  local mainDisplayBrightness = hs.brightness.get()
  if PREVIOUS_BRIGHTNESS ~= mainDisplayBrightness then
    PREVIOUS_BRIGHTNESS = mainDisplayBrightness
    local cmd = CMDFMT:format(ddcctl, 'b', mainDisplayBrightness)
    log:d('sync brightness with', cmd)
    hs.execute(cmd)
  else
    log:d('sync brightness: nothing changed')
  end
end

brightness_sync = hs.timer.new(5, syncMonitorBrightness, true)
brightness_sync:start()
