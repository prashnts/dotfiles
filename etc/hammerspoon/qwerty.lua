-- QWERTY reference on an Apple ISO board: hold Caps Lock to peek,
-- hyper+/ pins it. Big: what the key types (US + keys.lua). Orange: the cap.
-- Caps per machine: French by default, QWERTY ISO after (in the console)
-- hs.settings.set('qwerty.caps', 'iso').
local M = {}
local U, GAP, PAD = 52, 5, 14

local C = {
  bg = {white = 0.08, alpha = 0.94},
  key = {white = 0.2},
  sym = {red = 0.15, green = 0.24, blue = 0.38},
  mod = {white = 0.13},
  text = {white = 0.95},
  shift = {white = 0.62},
  cap = {red = 1, green = 0.6, blue = 0.2},
}

local function k(base, shift, cap) return {base = base, shift = shift, cap = cap, w = 1} end
local function mod(label, w, cap) return {base = label, cap = cap, w = w, mod = true} end
local function letters(us, fr)
  local t = {}
  for i = 1, #us do
    local c, f = us:sub(i, i), fr:sub(i, i)
    t[#t + 1] = k(c:upper(), nil, f ~= c and f:upper() or nil)
  end
  return t
end
local function row(...)
  local r = {}
  for _, part in ipairs({...}) do
    if part.base then r[#r + 1] = part else table.move(part, 1, #part, #r + 1, r) end
  end
  return r
end

local return2 = mod('', 0.75)
return2.up = true  -- lower half of the ISO Return, drawn up into row 2
local rows = {
  row(k('`', '~', '@'), k('1', '!', '&'), k('2', '@', 'é'), k('3', '#', '"'),
      k('4', '$', "'"), k('5', '%', '('), k('6', '^', '§'), k('7', '&', 'è'),
      k('8', '*', '!'), k('9', '(', 'ç'), k('0', ')', 'à'), k('-', '_', ')'),
      k('=', '+', '-'), mod('⌫', 1.5)),
  row(mod('⇥', 1.5), letters('qwertyuiop', 'azertyuiop'),
      k('[', '{', '^'), k(']', '}', '$'), mod('⏎', 1)),
  row(mod('✦', 1.75), letters('asdfghjkl', 'qsdfghjkl'),
      k(';', ':', 'm'), k("'", '"', 'ù'), k('\\', '|', '`'), return2),
  row(mod('⇧', 1.25), mod('⇧', 1, '<'), letters('zxcvbnm', 'wxcvbn,'),
      k(',', '<', ';'), k('.', '>', ':'), k('/', '?', '='), mod('⇧', 2.25)),
}
if hs.settings.get('qwerty.caps') == 'iso' then
  -- QWERTY caps match what the keys type, except the two keys.lua swaps.
  for _, r in ipairs(rows) do
    for _, key in ipairs(r) do key.cap = nil end
  end
  rows[1][1].cap, rows[4][2].cap = '§', '`'
end

local function text(s, x, y, w, size, color)
  return {type = 'text', text = s, textSize = size, textColor = color,
          textFont = 'Menlo', textAlignment = 'center',
          frame = {x = x, y = y, w = w, h = size + 6}}
end

local function build()
  local W, H = 14.5 * U + 2 * PAD - GAP, #rows * U + 2 * PAD - GAP
  local f = hs.screen.mainScreen():frame()
  local c = hs.canvas.new{x = f.x + (f.w - W) / 2, y = f.y + f.h - H - 60, w = W, h = H}
  c:level(hs.canvas.windowLevels.overlay)
  c:behaviorAsLabels({'canJoinAllSpaces', 'stationary'})
  c:appendElements({type = 'rectangle', action = 'fill', fillColor = C.bg,
                    roundedRectRadii = {xRadius = 12, yRadius = 12}})
  for r, keys in ipairs(rows) do
    local x, y = PAD, PAD + (r - 1) * U
    for _, key in ipairs(keys) do
      local w, top, h = key.w * U - GAP, y, U - GAP
      if key.up then top, h = y - U, 2 * U - GAP end
      local fill = key.mod and C.mod or key.shift and C.sym or C.key
      c:appendElements({type = 'rectangle', action = 'fill', fillColor = fill,
                        roundedRectRadii = {xRadius = 6, yRadius = 6},
                        frame = {x = x, y = top, w = w, h = h}})
      if key.shift then
        c:appendElements(text(key.shift, x, y + 3, w, 15, C.shift),
                         text(key.base, x, y + 21, w, 19, C.text))
      else
        c:appendElements(text(key.base, x, y + 12, w, 18, C.text))
      end
      if key.cap then
        c:appendElements(text(key.cap, x + w - 18, y + 1, 16, 11, C.cap))
      end
      x = x + key.w * U
    end
  end
  return c
end

function M.show()
  if M.canvas then M.canvas:delete() end
  M.canvas = build():show()
end

function M.hide()
  if M.canvas then M.canvas:delete(); M.canvas = nil end
  M.pinned = false
end

function M.peek(on)
  if on then
    if not M.canvas then M.show() end
  elseif not M.pinned then
    M.hide()
  end
end

function M.pin()
  if M.pinned then M.hide() else M.show(); M.pinned = true end
end

return M
