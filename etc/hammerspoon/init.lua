-- Hammerspoon: replaces BetterTouchTool + Karabiner, plus wifi-sleep.
-- Needs Accessibility only. No hs.ipc: it lets any local process run Lua here.
-- Older modules (ddcci, popouts, spotify, ...) are kept but not loaded.
hs.window.animationDuration = 0
hs.allowAppleScript(false)

local keys = require 'keys'
local qwerty = require 'qwerty'
local wifi = require 'wifisleep'
local space = require 'space'
local apps = require 'apps'
require 'ndot'
require 'switcher'
require 'moonlight'

-- Caps Lock held alone: QWERTY peek. Caps Lock + key: hyper.
keys.hold(function() qwerty.peek(true) end, function() qwerty.peek(false) end)
keys.bind('/', qwerty.pin)
keys.bind('w', wifi.toggle)
keys.bind('r', hs.reload)
keys.bind('space', space.run)
keys.bind('s', apps.focus('md.obsidian'))
keys.forward('abcdefghijklmnopqrstuvwxyz0123456789')

hs.alert.show('Hammerspoon ready', 0.5)
