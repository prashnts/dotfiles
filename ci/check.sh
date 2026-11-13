#!/bin/sh
# Cheap repo checks, also run by .github/workflows/check.yml.
# Needs: luac (5.4, as in Hammerspoon), shellcheck, zsh.
set -u
cd "$(dirname "$0")/.."
fail=0
bad() { echo "FAIL: $*"; fail=1; }

# Lua: syntax, then globals set or read that are not Lua or Hammerspoon's.
known='hs|spoon|require|print|pairs|ipairs|next|type|tostring|tonumber|select'
known="$known|pcall|xpcall|error|assert|setmetatable|getmetatable|rawget|rawset"
known="$known|rawequal|rawlen|load|dofile|collectgarbage|string|table|math|os"
known="$known|io|utf8|coroutine|debug|package|_G"
# Globals only for loaded Hammerspoon modules (old unused ones use some).
hsdir=etc/hammerspoon
loaded="$hsdir/init.lua $(sed -nE \
  "s|^.*require '([a-z]+)'.*$|$hsdir/\\1.lua|p" $hsdir/init.lua | tr '\n' ' ')"
for f in $(git ls-files '*.lua'); do
  luac -p "$f" || { bad "$f: syntax"; continue; }
  case " $loaded " in *" $f "*) ;; *) continue ;; esac
  luac -l -l -p "$f" | grep -oE '(GET|SET)TABUP.*_ENV "[^"]+"' \
    | sed -E 's/^(GET|SET)TABUP.*_ENV "([^"]+)"/\1 \2/' | sort -u \
    | while read -r op name; do
        if [ "$op" = SET ]; then echo "FAIL: $f: sets global $name"; exit 1; fi
        echo "$name" | grep -qxE "$known" \
          || { echo "FAIL: $f: unknown global $name"; exit 1; }
      done || fail=1
done

# Shell: errors only (old scripts carry style warnings).
sh_files=$(git ls-files '*.sh' bin | while read -r f; do
  head -n1 "$f" | grep -qE '^#!.*(ba|da)?sh' && echo "$f"; done)
shellcheck -S error $sh_files || bad shellcheck

# zsh: parse every tracked zsh file of riptide and the runcoms.
for f in $(git ls-files riptide | grep -E '\.zsh$|/runcoms/z'); do
  zsh -n "$f" || bad "$f: zsh syntax"
done

[ $fail = 0 ] && echo "all checks passed"
exit $fail
