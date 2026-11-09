#!/bin/sh
# Links riptide (zsh) + tmux config into $HOME. Safe to re-run.
#   install.sh [-c class|0-255] [-y]
# -c sets the prompt host color class (see riptide/.zpreztorc), -y never asks.
# Existing files are moved to ~/.dotfiles-backup/<time>/, links are replaced.
set -eu

repo=$(cd "$(dirname "$0")" && pwd -P)
dest=${ZDOTDIR:-$HOME}
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
class='' ask=1
while getopts c:y opt; do
  case $opt in
    c) class=$OPTARG ;;
    y) ask=0 ;;
    *) sed -n 3,4p "$0" >&2; exit 2 ;;
  esac
done

command -v zsh >/dev/null || { echo "zsh is not installed" >&2; exit 1; }
# Only fetch missing plugins: never reset a checkout (bootstrap.sh updates).
if git -C "$repo" submodule status | grep -q '^-'; then
  git -C "$repo" submodule update --init --recursive
fi

link() {  # link <source in repo> <target>
  if [ -L "$2" ]; then
    rm "$2"
  elif [ -e "$2" ]; then
    mkdir -p "$backup"
    mv "$2" "$backup/"
    echo "backed up $2"
  fi
  ln -s "$1" "$2"
  echo "$2 -> $1"
}

for rc in zshenv zprofile zshrc zlogin zlogout; do
  link "$repo/riptide/runcoms/$rc" "$dest/.$rc"
done
link "$repo/riptide/tmux/tmux.conf" "$HOME/.tmux.conf"
if [ -d "$repo/riptide/tmux/tmuxinator" ]; then
  mkdir -p "$HOME/.config"
  link "$repo/riptide/tmux/tmuxinator" "$HOME/.config/tmuxinator"
fi
if [ "$(uname)" = Darwin ]; then
  link "$repo/etc/hammerspoon" "$HOME/.hammerspoon"
fi

# History: riptide uses ~/.zhistory, omz used ~/.zsh_history (same format).
# Old lines first, then link the old name so both stay in one file.
old_hist="$dest/.zsh_history" hist="$dest/.zhistory"
if [ -f "$old_hist" ] && [ ! -L "$old_hist" ]; then
  mkdir -p "$backup"
  cp -p "$old_hist" "$backup/"
  if [ -f "$hist" ]; then
    cat "$old_hist" "$hist"
  else
    cat "$old_hist"
  fi > "$hist.tmp"
  chmod 600 "$hist.tmp"
  mv "$hist.tmp" "$hist"
  rm "$old_hist"
  ln -s .zhistory "$old_hist"
  echo "merged $old_hist into $hist"
fi

# Prompt host color: pick a class, store it in ~/.zpreztorc.local.
local_rc="$dest/.zpreztorc.local"
style=":prezto:module:prompt:damned:host"
colors=$(zsh -fc "source '$repo/riptide/.zpreztorc'
  zstyle -a '$style' colors c; print -r -- \$c")
host=$(hostname -s 2>/dev/null || hostname)
current=$(zsh -fc "source '$local_rc' 2>/dev/null; zstyle -s '$style' class c && print -r -- \$c" || true)
guess=${current:-${host%%[-._0-9]*}}
if [ -z "$class" ] && [ "$ask" = 1 ] && [ -r /dev/tty ]; then
  echo "prompt host color for $host:"
  set -- $colors
  while [ $# -ge 2 ]; do
    printf '  \033[48;5;%sm\033[38;5;252m %s \033[0m' "$2" "$1"
    shift 2
  done
  printf '\nclass or 0-255 [%s]: ' "$guess"
  read -r class < /dev/tty || class=''
fi
class=${class:-$guess}
case " $colors " in
  *" $class "*) ;;
  *) case $class in
       *[!0-9]*|'') echo "unknown class '$class', using 'other'"; class=other ;;
     esac ;;
esac
touch "$local_rc"
grep -v "^zstyle '$style' class " "$local_rc" > "$local_rc.tmp" || true
echo "zstyle '$style' class '$class'" >> "$local_rc.tmp"
mv "$local_rc.tmp" "$local_rc"
echo "host class: $class (in $local_rc)"

if [ -d "$backup" ]; then
  echo "old files in $backup: move secrets/host bits to ~/.zprofile.local or ~/.zshrc.local"
fi
case "${SHELL:-}" in
  */zsh) ;;
  *) echo "login shell is ${SHELL:-unset}; run: chsh -s $(command -v zsh)" ;;
esac
