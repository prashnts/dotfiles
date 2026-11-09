-- Wi-Fi off while asleep, back on at a real wake (was bin/wifi-sleep).
-- bcmwlan panics on dark wakes; screensDidWake/Unlock only follow a real one.
-- Menu bar: ☾ on, ☼ off, ! = still off from sleep. hyper+w flips Wi-Fi now.
local M = {}
local NS = '/usr/sbin/networksetup'
local OFF = 'wifisleep.off'      -- set while Wi-Fi is off because of us
local ENABLED = 'wifisleep.enabled'
local cw = hs.caffeinate.watcher

M.dev = hs.execute(NS .. ' -listallhardwareports')
  :match('Hardware Port: Wi%-Fi\nDevice: (%S+)') or 'en0'

function M.power()
  return hs.execute(NS .. ' -getairportpower ' .. M.dev):find(': On') ~= nil
end

local function set(on)
  hs.execute(('%s -setairportpower %s %s'):format(NS, M.dev, on and 'on' or 'off'))
end

function M.enabled() return hs.settings.get(ENABLED) ~= false end

local function sleep()
  if M.enabled() and M.power() then
    set(false)
    hs.settings.set(OFF, true)
  end
end

local function wake(try)
  try = try or 1
  if not hs.settings.get(OFF) then return end
  set(true)
  if M.power() then
    hs.settings.clear(OFF)
  elseif try < 5 then  -- driver may still be coming up
    M.retry = hs.timer.doAfter(2, function() wake(try + 1) end)
  end
  M.draw()
end

function M.toggle()
  local on = not M.power()
  set(on)
  hs.settings.clear(OFF)
  hs.alert.show('Wi-Fi ' .. (on and 'on' or 'off'), 0.8)
  M.draw()
end

function M.setEnabled(on)
  hs.settings.set(ENABLED, on)
  M.draw()
end

M.bar = hs.menubar.new()
function M.draw()
  M.bar:setTitle((M.enabled() and '☾' or '☼') .. (hs.settings.get(OFF) and '!' or ''))
end
M.bar:setTooltip('wifi-sleep')
M.bar:setMenu(function()
  return {
    {title = 'Wi-Fi (' .. M.dev .. ')', checked = M.power(), fn = M.toggle},
    {title = 'Off during sleep', checked = M.enabled(),
     fn = function() M.setEnabled(not M.enabled()) end},
  }
end)

M.watcher = cw.new(function(e)
  if e == cw.systemWillSleep then
    sleep()
  elseif e == cw.screensDidWake or e == cw.screensDidUnlock
      or e == cw.sessionDidBecomeActive then
    wake()
  end
end):start()

M.draw()
wake()  -- reload, or Hammerspoon restarted while Wi-Fi was off

return M
