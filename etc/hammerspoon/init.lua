require 'hs.ipc'
require 'libzen'
require 'consts'

hs.loadSpoon('RoundedCorners')

-- Set current working directory to ~/.hammerspoon. This used to be _not_
-- required, but as of 2021 May, I keep running into error with hs.fs.currentDir
-- which does not return any value. So we're hardcoding config location to home.
hs.fs.chdir("~/.hammerspoon")

-- Set docs server
hs.doc.hsdocs.forceExternalBrowser(true)
hs.doc.hsdocs.moduleEntitiesInSidebar(true)
hs.doc.hsdocs.browserDarkMode(false)

local log = hs.logger.new('riptide', 'debug')

-- Bring all Finder windows forward when one gets activated
function cascadingWindowActivationHandler(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (appName:has('Finder')) then
      appObject:selectMenuItem({"Window", "Bring All to Front"})
    elseif (appName:has('ImageJ')) then
      appObject:mainWindow():selectMenuItem({"Window", "Show All"})
    end
  end
end
appWatcher = hs.application.watcher.new(cascadingWindowActivationHandler)
appWatcher:start()

-- Misc actions
function startScreenSaver()
  hs.caffeinate.startScreensaver()
end

function lockScreen()
  hs.caffeinate.lockScreen()
end

-- Rounded Corners
rcorners = spoon.RoundedCorners:start()


-- Show an icon if we're using an Airplay Speaker
local airplayStatusIcon = hs.menubar.new()
  :setIcon(getIcon('airplay', 16))
  :setTooltip('Using Airplay Audio')
  :removeFromMenuBar()

function airplayStatus(_)
  if (hs.audiodevice.current().name:has('Bunker')) then
    airplayStatusIcon:returnToMenuBar()
    log:i('Using Airplay, enabled icon.')
  else
    airplayStatusIcon:removeFromMenuBar()
    log:i('Not using Airplay, disabled icon.')
  end
end

hs.audiodevice.watcher.setCallback(airplayStatus)
hs.audiodevice.watcher.start()
airplayStatus(nil)

-- Network Reachability
local noNetworkStatusIcon = hs.menubar.new()
  :setIcon(getIcon('triangle', 16))
  :setTooltip('No network')
  :removeFromMenuBar()

function networkStatus(self, flags)
  if (flags & hs.network.reachability.flags.reachable) > 0 then
    noNetworkStatusIcon:removeFromMenuBar()
  else
    noNetworkStatusIcon:returnToMenuBar()
  end
end

hs.network.reachability.internet():setCallback(networkStatus):start()


-- USB Serial Device Port
function publishUSBSerialPort(device)
  log:d(hs.inspect(device))
end

local usb = hs.usb.watcher.new(publishUSBSerialPort):start()

-- Auto Reload the Config File on Changes
hs.notify.register('#reloadConfig', hs.reload)
function askForConfigReload(paths, flags)
  if (flags[1].itemRenamed) then
    log:d('Reloading Config File')
    hs.notify.new('#reloadConfig')
      :autoWithdraw(true)
      :title('Riptide Spoons')
      :subTitle('Reload Configuration File?')
      :actionButtonTitle('Reload')
      :setIdImage(getIcon('reload', 20))
      :send()
  end
end
local configWatcher = hs.pathwatcher.new('./init.lua', askForConfigReload):start()
