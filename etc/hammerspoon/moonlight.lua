-- Mac keys in Moonlight (Linux host): only while Moonlight is frontmost.
-- ⌘ never reaches the host as Super on its own (no Plasma launcher):
--   ⌘+letter/digit/punct -> Ctrl+same (copy, save, undo, KiCad's Ctrl keys)
--   ⌘⌫ -> Delete (KiCad delete), ⌘←/→ -> Home/End, ⌘↑/↓ -> Ctrl+Home/End
--   ⌥←/→ -> Ctrl+←/→ (word), ⌥⌫ -> Ctrl+Backspace
--   other ⌘ keys (return, F-keys, ...) -> Super+key, for Plasma shortcuts
-- Physical Ctrl is left alone: Ctrl+C stays SIGINT. ⌘⇥ stays the Mac's.
local M = {}
M.bundleID = 'com.moonlight-stream.Moonlight'

local ev = hs.eventtap.event
local T, P = ev.types, ev.properties
local K = hs.keycodes.map
local MARK = 0x4D4C  -- our own posted events carry this, the tap skips them

local special = {
  cmd = {
    [K.delete] = {{}, K.forwarddelete},
    [K.left] = {{}, K.home}, [K.right] = {{}, K['end']},
    [K.up] = {{'ctrl'}, K.home}, [K.down] = {{'ctrl'}, K['end']},
  },
  alt = {
    [K.left] = {{'ctrl'}, K.left}, [K.right] = {{'ctrl'}, K.right},
    [K.delete] = {{'ctrl'}, K.delete},
  },
}
-- Keys whose ⌘ form becomes Ctrl: anything that types a character.
local typing = {}
for c in ('abcdefghijklmnopqrstuvwxyz0123456789-=[];\',./\\`'):gmatch('.') do
  if K[c] then typing[K[c]] = true end
end
local passthrough = {[K.tab] = true, [K.space] = true}  -- Mac's own ⌘⇥/⌘␣

local function post(e)
  e:setProperty(P.eventSourceUserData, MARK):post()
end
local function mod(name, down) post(ev.newKeyEvent(name, down)) end

-- Key press with mods held around it, as real modifier events for SDL.
local function stroke(mods, code, shift)
  if shift then mods = hs.fnutils.concat({'shift'}, mods) end
  for _, m in ipairs(mods) do if m ~= 'shift' then mod(m, true) end end
  post(ev.newKeyEvent(mods, code, true))
  post(ev.newKeyEvent(mods, code, false))
  for _, m in ipairs(mods) do if m ~= 'shift' then mod(m, false) end end
end

local CMD = {[K.cmd] = true, [K.rightcmd] = true}
local swallowUp = {}

M.tap = hs.eventtap.new({T.keyDown, T.keyUp, T.flagsChanged}, function(e)
  if e:getProperty(P.eventSourceUserData) == MARK then return false end
  local t, code, f = e:getType(), e:getKeyCode(), e:getFlags()
  if t == T.flagsChanged then return CMD[code] or false end
  if t == T.keyUp then
    if swallowUp[code] then swallowUp[code] = nil; return true end
    return false
  end
  local s
  if f.cmd and not (f.ctrl or f.alt) then
    if passthrough[code] then return false end
    s = special.cmd[code] or (typing[code] and {{'ctrl'}, code})
      or {{'cmd'}, code}
  elseif f.alt and not (f.ctrl or f.cmd) then
    s = special.alt[code]
    if not s then return false end
    mod('alt', false)  -- the host holds Alt: let go around the stroke
    stroke(s[1], s[2], f.shift)
    mod('alt', true)
    swallowUp[code] = true
    return true
  else
    return false
  end
  stroke(s[1], s[2], f.shift)
  swallowUp[code] = true
  return true
end)

M.watcher = hs.application.watcher.new(function(_, kind, app)
  if kind ~= hs.application.watcher.activated then return end
  if app and app:bundleID() == M.bundleID then M.tap:start() else M.tap:stop() end
end):start()

local front = hs.application.frontmostApplication()
if front and front:bundleID() == M.bundleID then M.tap:start() end

-- macOS disables a tap that once answered too slowly: switch it back on.
M.watchdog = hs.timer.doEvery(5, function()
  local app = hs.application.frontmostApplication()
  if app and app:bundleID() == M.bundleID and not M.tap:isEnabled() then
    M.tap:start()
  end
end)

return M
