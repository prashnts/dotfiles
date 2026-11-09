-- Key remaps (was Karabiner) and Caps Lock as hyper (was BetterTouchTool).
-- hidutil remaps HID usages below the layout: French ISO board, US layout.
-- Quit Karabiner first, it grabs the keyboard. Undo: keys.reset().
local M = {}

local CAPS, F18, GRAVE, ISO, LSHIFT = 0x39, 0x6D, 0x35, 0x64, 0xE1
M.all = {{CAPS, F18}}  -- every keyboard: Caps Lock -> F18, the hyper trigger
M.builtin = {          -- the French ISO laptop board only
  {CAPS, F18},
  {GRAVE, ISO},        -- @# top left -> `~ (macOS swaps these two on ISO)
  {ISO, LSHIFT},       -- <> left of W -> Left Shift
}
M.HYPER = {'cmd', 'alt', 'ctrl', 'shift'}

local function hidutil(maps, match)
  local t = {}
  for _, m in ipairs(maps) do
    t[#t + 1] = ('{"HIDKeyboardModifierMappingSrc":%d,'
      .. '"HIDKeyboardModifierMappingDst":%d}')
      :format(0x700000000 + m[1], 0x700000000 + m[2])
  end
  match = match and ("--matching '%s' "):format(match) or ''
  hs.execute(("/usr/bin/hidutil property %s--set '{\"UserKeyMapping\":[%s]}'")
    :format(match, table.concat(t, ',')))
end

-- Global first: it would overwrite the built-in board's own list.
function M.apply()
  hidutil(M.all)
  hidutil(M.builtin, '{"Built-In":true}')
end
function M.reset() hidutil({}) end

-- Hyper: a modal that is on while F18 (Caps Lock) is held.
M.modal = hs.hotkey.modal.new()
local bound, used = {}, false

function M.bind(key, fn)
  bound[key] = true
  M.modal:bind({}, key, function() used = true; fn() end)
end

-- Keys without a binding go out as ⌃⌥⇧⌘+key, for apps' own shortcuts.
function M.forward(keys)
  for key in keys:gmatch('.') do
    if not bound[key] then
      local send = function()
        used = true
        hs.eventtap.keyStroke(M.HYPER, key, 1000)
      end
      M.modal:bind({}, key, send, nil, send)
    end
  end
end

-- down/up run when Caps Lock is held alone for a moment, and on release.
function M.hold(down, up) M.onHold, M.onRelease = down, up end

M.trigger = hs.hotkey.bind({}, 'f18', function()
  used = false
  M.modal:enter()
  if M.onHold then
    M.timer = hs.timer.doAfter(0.25, function()
      if not used then M.held = true; M.onHold() end
    end)
  end
end, function()
  M.modal:exit()
  if M.timer then M.timer:stop() end
  if M.held then M.held = false; M.onRelease() end
end)

-- hidutil maps can drop on wake or when a keyboard is plugged in.
local cw = hs.caffeinate.watcher
M.watcher = cw.new(function(e)
  if e == cw.systemDidWake or e == cw.screensDidUnlock then M.apply() end
end):start()
M.usb = hs.usb.watcher.new(function(d)
  if d.eventType == 'added' then M.apply() end
end):start()
M.apply()

return M
