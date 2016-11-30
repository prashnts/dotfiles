-- === "standard" library ===
--
-- Check if string contains some other string
-- Usage: "it's all in vain":has("vain") == true
function string:has(pattern)
  -- Don't laugh. Loaded lua might not have a toboolean method.
  if self:match(pattern) then return true else return false end
end
