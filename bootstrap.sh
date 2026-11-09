#!/bin/sh
# New or existing host, one line (args go to install.sh):
#   curl -fsSL https://raw.githubusercontent.com/prashnts/dotfiles/master/bootstrap.sh | sh
#   curl -fsSL .../bootstrap.sh | sh -s -- -c pi -y
# Installs git + zsh if missing, clones or fast-forwards the repo, runs install.sh.
# Env: DOTFILES (default ~/repo/dotfiles), DOTFILES_URL, DOTFILES_REF (branch/tag).

# Everything runs from main, called on the last line: a cut-off download
# can't run half a script.
main() {
  set -eu
  dir=${DOTFILES:-$HOME/repo/dotfiles}
  url=${DOTFILES_URL:-https://github.com/prashnts/dotfiles.git}
  ref=${DOTFILES_REF:-master}

  missing=''
  for c in git zsh; do
    command -v "$c" >/dev/null || missing="$missing $c"
  done
  if [ -n "$missing" ]; then
    echo "installing:$missing"
    sudo=''
    [ "$(id -u)" -ne 0 ] && sudo=sudo
    if command -v apt-get >/dev/null; then
      $sudo apt-get update -q && $sudo apt-get install -y $missing
    elif command -v dnf >/dev/null; then
      $sudo dnf install -y $missing
    elif command -v pacman >/dev/null; then
      $sudo pacman -S --noconfirm $missing
    elif command -v brew >/dev/null; then
      brew install $missing
    else
      echo "no known package manager, install$missing first" >&2
      exit 1
    fi
  fi

  if [ -d "$dir/.git" ]; then
    if [ -n "$(git -C "$dir" status --porcelain --ignore-submodules)" ]; then
      echo "$dir has local changes, not pulling"
    else
      git -C "$dir" fetch -q origin "$ref"
      git -C "$dir" merge -q --ff-only FETCH_HEAD \
        || echo "$dir can't fast-forward to $ref, left as is"
      git -C "$dir" submodule update -q --init --recursive
    fi
  elif [ -e "$dir" ]; then
    echo "$dir exists and is not a git repo" >&2
    exit 1
  else
    mkdir -p "$(dirname "$dir")"
    git clone -q --recursive --branch "$ref" "$url" "$dir"
  fi

  sh "$dir/install.sh" "$@"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh is unused now: rm -rf ~/.oh-my-zsh when happy"
  fi
  echo "done: exec zsh -l"
}

main "$@"
