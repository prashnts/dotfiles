dotfiles
========

Useless (and useful!) stuffs I do to my terminal.

- `riptide/`: my zsh setup, a Prezto fork (upstream
  modules in `riptide/contrib/`).
- `riptide/tmux/tmux.conf`: tmux
- `bin/`: small scripts, on `$PATH`.

**gibbrish**:

on new or existing host (installs git/zsh if missing, re-run to update):

    curl -fsSL https://raw.githubusercontent.com/prashnts/dotfiles/master/bootstrap.sh | sh

or: `./install.sh [-c class] [-y]`.

Links `~/.zshenv ~/.zprofile ~/.zshrc ~/.zlogin ~/.zlogout ~/.tmux.conf`. Existing files go to `~/.dotfiles-backup/`.
Not checked in (secrets and host-only bits): `~/.zprofile.local`,
`~/.zshrc.local`, `~/.zpreztorc.local`.

