require 'libzen'
require 'iTerm2'
require 'spotify'
-- require 'popouts'

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

-- local capsTap = hs.eventtap.new(
--   {'all.'},
--   function (e)
--     print(hs.inspect(e:getRawEventData()))
--   end
-- )
-- capsTap:start()
