-- Menu bar dot when the dotfiles remote has commits we don't (bin/ndot check:
-- read-only ls-remote). Never pulls, that's `ndot update` in a shell.
-- Reloads when ndot applies an update (it writes ~/.cache/ndot/rev).
local M = {}
local repo = hs.fs.pathToAbsolute(hs.configdir .. '/../..')
local NDOT = repo .. '/bin/ndot'
local CACHE = os.getenv('HOME') .. '/.cache'
local EVERY = 3 * 3600

M.bar = hs.menubar.new(false)  -- shown only with an update

local function show(sha)
  if not sha then return M.bar:removeFromMenuBar() end
  M.bar:returnToMenuBar()
  M.bar:setTitle('•')
  M.bar:setTooltip('dotfiles: update available')
  M.bar:setMenu({
    {title = 'dotfiles: ' .. sha:sub(1, 7) .. ' on the remote', disabled = true},
    {title = 'Copy “ndot update”',
     fn = function() hs.pasteboard.setContents('ndot update') end},
    {title = 'Check now', fn = M.check},
  })
end

function M.check()
  if M.task and M.task:isRunning() then return end
  M.task = hs.task.new(NDOT, function(code, out)
    if code == 10 then show(out:match('%x+')) elseif code == 0 then show() end
  end, {'check'})  -- other codes (offline): keep what we showed
  M.task:start()
end

hs.fs.mkdir(CACHE)
hs.fs.mkdir(CACHE .. '/ndot')
M.watch = hs.pathwatcher.new(CACHE .. '/ndot', hs.reload):start()
M.timer = hs.timer.doEvery(EVERY, M.check)
M.first = hs.timer.doAfter(10, M.check)

return M
