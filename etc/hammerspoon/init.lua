require 'hs.ipc'
require 'ddcci'

local log = hs.logger.new('riptide', 'debug')

-- Bring all Finder windows forward when one gets activated
function finderActivationHandler(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      appObject:selectMenuItem({"Window", "Bring All to Front"})
    end
  end
end
appWatcher = hs.application.watcher.new(finderActivationHandler)
appWatcher:start()
