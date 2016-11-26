# exit the script if any statement returns a non-true return value
set -e

__newline='
'

_is_enabled() {
  ( ([ x"$1" = x"enabled" ] || [ x"$1" = x"true" ] || [ x"$1" = x"yes" ] || [ x"$1" = x"1" ]) && return 0 ) || return 1
}

_circled_digit() {
  circled_digits='⓪ ① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳'
  if [ "$1" -le 20 ] 2>/dev/null; then
    i=$(( $1 + 1 ))
    eval set -- "$circled_digits"
    eval echo "\${$i}"
  else
    echo "$1"
  fi
}

_maximize_pane() {
  current_session=${1:-$(tmux display -p '#{session_name}')}
  current_pane=${2:-$(tmux display -p '#{pane_id}')}

  dead_panes=$(tmux list-panes -s -t "$current_session" -F '#{pane_dead} #{pane_id} #{pane_start_command}' | grep -o '^1 %.\+maximized.\+$' || true)
  restore=$(echo "$dead_panes" | sed -n -E -e "s/^1 $current_pane .+maximized.+(%[0-9]+)$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t $current_pane/p" -e "s/^1 (%[0-9]+) .+maximized.+$current_pane$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t \1/p" )

  if [ -z "$restore" ]; then
    [ "$(tmux list-panes -t "$current_session:" | wc -l | sed 's/^ *//g')" -eq 1 ] && tmux display "Can't maximize with only one pane" && return
    window=$(tmux new-window -t "$current_session:" -P "exec maximized... 2> /dev/null & tmux setw -t $current_session remain-on-exit on; printf 'Pane has been maximized, press <prefix>+ to restore. %s' \\$current_pane")
    window=${window%.*}

    guard=10
    while [ x"$(tmux list-panes -t "$window" -F '#{session_name}:#{window_index} #{pane_dead}' 2>/dev/null)" != x"$window 1" ] && [ "$guard" -ne 0 ]; do
      sleep 0.01
      guard=$((guard - 1))
    done
    if [ "$guard" -eq 0 ]; then
      tmux display 'Unable to maximize pane'
    fi

    new_pane=$(tmux display -p '#{pane_id}')
    tmux setw -t "$window" remain-on-exit off \; swap-pane -s "$current_pane" -t "$new_pane"
  else
    $restore || tmux kill-pane
  fi
}

_toggle_mouse() {
  if tmux show -g -w | grep -q mode-mouse; then
    old=$(tmux show -g -w | grep mode-mouse | cut -d' ' -f2)
    new=""

    if [ "$old" = "on" ]; then
      new="off"
    else
      new="on"
    fi

    tmux set -g mode-mouse $new \;\
         set -g mouse-resize-pane $new \;\
         set -g mouse-select-pane $new \;\
         set -g mouse-select-window $new \;\
         display "mouse: $new"
  else
    old=$(tmux show -g | grep mouse | head -n 1 | cut -d' ' -f2)
    new=""

    if [ "$old" = "on" ]; then
      new="off"
    else
      new="on"
    fi

    tmux set -g mouse $new \;\
         display "mouse: $new"
  fi
}

_username() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  ssh_only=$2
  # shellcheck disable=SC2039
  if [ x"$OSTYPE" = x"cygwin" ]; then
    pid=$(ps -a | awk -v tty="${tty##/dev/}" '$5 == tty && /ssh/ && && !/vagrant ssh/ && !/autossh/ && !/-W/ { print $1 }')
    [ -n "$pid" ] && ssh_parameters=$(tr '\0' ' ' < "/proc/$pid/cmdline" | sed 's/^ssh //')
  else
    set -x
    ssh_parameters=$(ps -t "$tty" -o command= | awk '/ssh/ && !/vagrant ssh/ && !/autossh/ && !/-W/ { $1=""; print $0; exit }')
    set +x
  fi
  if [ -n "$ssh_parameters" ]; then
    # shellcheck disable=SC2086
    username=$(ssh -G $ssh_parameters 2>/dev/null | awk 'NR > 2 { exit } ; /^user / { print $2 }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%username%% %r >&2'" $ssh_parameters 2>&1 | awk '/^%username% / { print $2; exit }')
  else
    if ! _is_enabled "$ssh_only"; then
      # shellcheck disable=SC2039
      if [ x"$OSTYPE" = x"cygwin" ]; then
        username=$(whoami)
      else
        username=$(ps -t "$tty" -o user= -o pid= -o ppid= -o command= | awk '
          !/ssh/ { user[$2] = $1; ppid[$3] = 1 }
          END {
            for (i in user)
              if (!(i in ppid))
              {
                print user[i]
                exit
              }
          }
        ')
      fi
    fi
  fi

  echo "$username"
}

_hostname() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  ssh_only=$2
  # shellcheck disable=SC2039
  if [ x"$OSTYPE" = x"cygwin" ]; then
    pid=$(ps -a | awk -v tty="${tty##/dev/}" '$5 == tty && /ssh/ && !/vagrant ssh/ && !/autossh/ && !/-W/ { print $1 }')
    [ -n "$pid" ] && ssh_parameters=$(tr '\0' ' ' < "/proc/$pid/cmdline" | sed 's/^ssh //')
  else
    ssh_parameters=$(ps -t "$tty" -o command= | awk '/ssh/ && !/vagrant ssh/ && !/autossh/ && !/-W/ { $1=""; print $0; exit }')
  fi
  if [ -n "$ssh_parameters" ]; then
    # shellcheck disable=SC2086
    hostname=$(ssh -G $ssh_parameters 2>/dev/null | awk 'NR > 2 { exit } ; /^hostname / { print $2 }')
    # shellcheck disable=SC2086
    [ -z "$hostname" ] && hostname=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%hostname%% %h >&2'" $ssh_parameters 2>&1 | awk '/^%hostname% / { print $2; exit }')
    #shellcheck disable=SC1004
    hostname=$(echo "$hostname" | awk '\
    { \
      if ($1~/^[0-9.:]+$/) \
        print $1; \
      else \
        split($1, a, ".") ; print a[1] \
    }')
  else
    if ! _is_enabled "$ssh_only"; then
      hostname=$(command hostname -s)
    fi
  fi

  echo "$hostname"
}

_root() {
  username=$(_username "$tty" false "$@")
  if [ x"$username" = x"root" ]; then
    tmux show -gqv '@root'
  fi
}

_uptime() {
  case $(uname -s) in
    *Darwin*)
      boot=$(sysctl -q -n kern.boottime | awk -F'[ ,:]+' '{ print $4 }')
      now=$(date +%s)
      ;;
    *Linux*|*CYGWIN*)
      now=$(cut -d' ' -f1 < /proc/uptime)
      ;;
    *OpenBSD*)
      boot=$(sysctl -n kern.boottime)
      now=$(date +%s)
  esac
  # shellcheck disable=SC1004
  awk -v boot="$boot" -v now="$now" '
    BEGIN {
      uptime = now - boot
      d = int(uptime / 86400)
      h = int(uptime / 3600) % 24
      m = int(uptime / 60) % 60
      s = int(uptime) % 60

      system("tmux  set -g @uptime_d " d + 0 " \\; " \
                   "set -g @uptime_h " h + 0 " \\; " \
                   "set -g @uptime_m " m + 0 " \\; " \
                   "set -g @uptime_s " s + 0)
    }'
}

_loadavg() {
  case $(uname -s) in
    *Darwin*)
      tmux set -g @loadavg "$(sysctl -q -n vm.loadavg | cut -d' ' -f2)"
      ;;
    *Linux*)
      tmux set -g @loadavg "$(cut -d' ' -f1 < /proc/loadavg)"
      ;;
    *OpenBSD*)
      tmux set -g @loadavg "$(sysctl -q -n vm.loadavg | cut -d' ' -f1)"
      ;;
  esac
}

_ifstats() {
  tick=$(netstat -i -I en0 -b | grep -m 1 en0 | awk '{print $7,$10}')
  sleep 0.5
  tock=$(netstat -i -I en0 -b | grep -m 1 en0 | awk '{print $7,$10}')

  printf "%s  %s" ${@:1} $(echo $tick'\n'$tock | \
      awk '{i=$1-i; u=$2-u} END {print i / 128 / .5, u / 128 / .5}' | \
      awk '
        {for (i=1;i<=NF;i++) a[i] = sprintf("%d%s",
          ($i > 1024) ? $i / 1024 : $i,
          ($i > 1024) ? "m" : "k")}
        END {print a[1]}')
}

_split_window() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  shift
  # shellcheck disable=SC2039
  if [ x"$OSTYPE" = x"cygwin" ]; then
    pid=$(ps -a | sort -d | awk -v tty="${tty##/dev/}" '$5 == tty && /ssh/ && !/-W/ { print $1; exit 0 }')
    [ -n "$pid" ] && ssh=$(tr '\0' ' ' < "/proc/$pid/cmdline")
  else
    ssh=$(ps -t "$tty" -o command= | sort -d | awk '/ssh/ && !/-W/ { print $0; exit 0 }')
  fi
  if [ -n "$ssh" ]; then
    # shellcheck disable=SC2046
    tmux split-window "$@" $(echo "$ssh" | sed -e "s/;/\\\\;/g")
  else
    tmux split-window "$@"
  fi
}

_apply_overrides() {
  tx_t_24b_colour=${tx_t_24b_colour:-false}
  if _is_enabled "$tx_t_24b_colour"; then
  case "$TERM" in
    screen-*|tmux-*)
      ;;
    *)
      tmux set-option -ga terminal-overrides ",$TERM:Tc"
      ;;
  esac
  fi
}

_apply_bindings() {
  tmux_conf_new_window_retain_current_path=${tmux_conf_new_window_retain_current_path:-false}
  if _is_enabled "$tmux_conf_new_window_retain_current_path"; then
    tmux bind c new-window -c '#{pane_current_path}'
  else
    tmux bind c new-window
  fi

  tmux_conf_new_pane_retain_current_path=${tmux_conf_new_pane_retain_current_path:-true}
  tmux_conf_new_pane_reconnect_ssh=${tmux_conf_new_pane_reconnect_ssh:-false}
  if _is_enabled "$tmux_conf_new_pane_reconnect_ssh"; then
    if _is_enabled "$tmux_conf_new_pane_retain_current_path"; then
      tmux  bind '"'  run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -v -c '#{pane_current_path}'" \;\
            bind %    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -h -c '#{pane_current_path}'" \;\
            bind -    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -v -c '#{pane_current_path}'" \;\
            bind _    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -h -c '#{pane_current_path}'"
    else
      tmux  bind '"'  run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -v" \;\
            bind %    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -h" \;\
            bind -    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -v" \;\
            bind _    run "cut -c3- ~/.tmux.conf | sh -s _split_window #{pane_tty} -h"
    fi
  else
    if _is_enabled "$tmux_conf_new_pane_retain_current_path"; then
      tmux  bind '"'  split-window -v -c '#{pane_current_path}' \;\
            bind %    split-window -h -c '#{pane_current_path}' \;\
            bind -    split-window -v -c '#{pane_current_path}' \;\
            bind _    split-window -h -c '#{pane_current_path}'
    else
      tmux  bind '"'  split-window -v \;\
            bind %    split-window -h \;\
            bind -    split-window -v \;\
            bind _    split-window -h
    fi
  fi

  tmux_conf_new_session_prompt=${tmux_conf_new_session_prompt:-false}
  if _is_enabled "$tmux_conf_new_session_prompt"; then
    tmux bind C-c command-prompt -p new-session 'new-session -s "%%"'
  else
    tmux bind C-c new-session
  fi

  if tmux -q -L swap-pane-test -f /dev/null new-session -d \; new-window \; new-window \; swap-pane -t :1 \; kill-session; then
    tmux bind + run 'cut -c3- ~/.tmux.conf | sh -s _maximize_pane #{session_name} #D'
  else
    tmux bind + display 'your tmux version has a buggy swap-pane command - see ticket #108, fixed in upstream commit 78e783e'
  fi
}

_apply_theme() {

  # -- panes -------------------------------------------------------------

  tx_t_window_fg=${tx_t_window_fg:-default}
  tx_t_window_bg=${tx_t_window_bg:-default}
  tx_t_highlight_focused_pane=${tx_t_highlight_focused_pane:-false}
  tx_t_focused_pane_fg=${tx_t_focused_pane_fg:-'default'} # default
  tx_t_focused_pane_bg=${tx_t_focused_pane_bg:-'#0087d7'} # light blue

  # tmux 1.9 doesn't really like set -q
  if tmux show -g -w | grep -q window-style; then
    tmux setw -g window-style "fg=$tx_t_window_fg,bg=$tx_t_window_bg"

    if _is_enabled "$tx_t_highlight_focused_pane"; then
      tmux setw -g window-active-style "fg=$tx_t_focused_pane_fg,bg=$tx_t_focused_pane_bg"
    else
      tmux setw -g window-active-style default
    fi
  fi

  tx_t_pane_border_style=${tx_t_pane_border_style:-thin}
  tx_t_pane_border=${tx_t_pane_border:-'#444444'}               # light gray
  tx_t_pane_active_border=${tx_t_pane_active_border:-'#00afff'} # light blue
  tx_t_pane_border_fg=${tx_t_pane_border_fg:-$tx_t_pane_border}
  tx_t_pane_active_border_fg=${tx_t_pane_active_border_fg:-$tx_t_pane_active_border}
  case "$tx_t_pane_border_style" in
    fat)
      tx_t_pane_border_bg=${tx_t_pane_border_bg:-$tx_t_pane_border_fg}
      tx_t_pane_active_border_bg=${tx_t_pane_active_border_bg:-$tx_t_pane_active_border_fg}
      ;;
    thin|*)
      tx_t_pane_border_bg=${tx_t_pane_border_bg:-'default'}
      tx_t_pane_active_border_bg=${tx_t_pane_active_border_bg:-'default'}
      ;;
  esac
  tmux setw -g pane-border-style "fg=$tx_t_pane_border_fg,bg=$tx_t_pane_border_bg" \; set -g pane-active-border-style "fg=$tx_t_pane_active_border_fg,bg=$tx_t_pane_active_border_bg"

  tx_t_pane_indicator=${tx_t_pane_indicator:-'#00afff'}               # light blue
  tx_t_pane_active_indicator=${tx_t_pane_active_indicator:-'#00afff'} # light blue

  tmux set -g display-panes-colour "$tx_t_pane_indicator" \; set -g display-panes-active-colour "$tx_t_pane_active_indicator"

  # -- status line -------------------------------------------------------

  tx_t_left_separator_main=${tx_t_left_separator_main-''}
  tx_t_left_separator_sub=${tx_t_left_separator_sub-'|'}
  tx_t_right_separator_main=${tx_t_right_separator_main-''}
  tx_t_right_separator_sub=${tx_t_right_separator_sub-'|'}

  tx_t_message_fg=${tx_t_message_fg:-'#000000'}   # black
  tx_t_message_bg=${tx_t_message_bg:-'#ffff00'}   # yellow
  tx_t_message_attr=${tx_t_message_attr:-'bold'}
  tmux set -g message-style "fg=$tx_t_message_fg,bg=$tx_t_message_bg,$tx_t_message_attr"

  tx_t_message_command_fg=${tx_t_message_command_fg:-'#ffff00'} # yellow
  tx_t_message_command_bg=${tx_t_message_command_bg:-'#000000'} # black
  tx_t_message_command_attr=${tx_t_message_command_attr:-'bold'}
  tmux set -g message-command-style "fg=$tx_t_message_command_fg,bg=$tx_t_message_command_bg,$tx_t_message_command_attr"

  tx_t_mode_fg=${tx_t_mode_fg:-'#000000'} # black
  tx_t_mode_bg=${tx_t_mode_bg:-'#ffff00'} # yellow
  tx_t_mode_attr=${tx_t_mode_attr:-'bold'}
  tmux setw -g mode-style "fg=$tx_t_mode_fg,bg=$tx_t_mode_bg,$tx_t_mode_attr"

  tx_t_status_fg=${tx_t_status_fg:-'#8a8a8a'} # white
  tx_t_status_bg=${tx_t_status_bg:-'#080808'} # dark gray
  tx_t_status_attr=${tx_t_status_attr:-'none'}
  tmux  set -g status-style "fg=$tx_t_status_fg,bg=$tx_t_status_bg,$tx_t_status_attr"        \;\
        set -g status-left-style "fg=$tx_t_status_fg,bg=$tx_t_status_bg,$tx_t_status_attr"   \;\
        set -g status-right-style "fg=$tx_t_status_fg,bg=$tx_t_status_bg,$tx_t_status_attr"

  tx_t_window_status_fg=${tx_t_window_status_fg:-'#8a8a8a'} # white
  tx_t_window_status_bg=${tx_t_window_status_bg:-'#080808'} # dark gray
  tx_t_window_status_attr=${tx_t_window_status_attr:-'none'}
  tx_t_window_status_format=${tx_t_window_status_format:-'#I #W'}

  tx_t_window_status_current_fg=${tx_t_window_status_current_fg:-'#000000'} # black
  tx_t_window_status_current_bg=${tx_t_window_status_current_bg:-'#00afff'} # light blue
  tx_t_window_status_current_attr=${tx_t_window_status_current_attr:-'bold'}
  tx_t_window_status_current_format=${tx_t_window_status_current_format:-'#I #W'}
  if [ x"$(tmux show -g -v status-justify)" = x"right" ]; then
    tx_t_window_status_current_format="#[fg=$tx_t_window_status_current_bg,bg=$tx_t_window_status_bg]$tx_t_right_separator_main#[fg=default,bg=default,default] $tx_t_window_status_current_format #[fg=$tx_t_window_status_bg,bg=$tx_t_window_status_current_bg,none]$tx_t_right_separator_main"
  else
    tx_t_window_status_current_format="#[fg=$tx_t_window_status_bg,bg=$tx_t_window_status_current_bg]$tx_t_left_separator_main#[fg=default,bg=default,default] $tx_t_window_status_current_format #[fg=$tx_t_window_status_current_bg,bg=$tx_t_status_bg,none]$tx_t_left_separator_main"
  fi

  tx_t_window_status_format=$(echo "$tx_t_window_status_format" | sed 's%#{circled_window_index}%#(cut -c3- ~/.tmux.conf | sh -s _circled_digit #I)%g')
  tx_t_window_status_current_format=$(echo "$tx_t_window_status_current_format" | sed 's%#{circled_window_index}%#(cut -c3- ~/.tmux.conf | sh -s _circled_digit #I)%g')

  tmux  setw -g window-status-style "fg=$tx_t_window_status_fg,bg=$tx_t_window_status_bg,$tx_t_window_status_attr" \;\
        setw -g window-status-format "$tx_t_window_status_format" \;\
        setw -g window-status-current-style "fg=$tx_t_window_status_current_fg,bg=$tx_t_window_status_current_bg,$tx_t_window_status_current_attr" \;\
        setw -g window-status-current-format "$tx_t_window_status_current_format"

  tx_t_window_status_activity_fg=${tx_t_window_status_activity_fg:-'default'}
  tx_t_window_status_activity_bg=${tx_t_window_status_activity_bg:-'default'}
  tx_t_window_status_activity_attr=${tx_t_window_status_activity_attr:-'underscore'}
  tmux setw -g window-status-activity-style "fg=$tx_t_window_status_activity_fg,bg=$tx_t_window_status_activity_bg,$tx_t_window_status_activity_attr"

  tx_t_window_status_bell_fg=${tx_t_window_status_bell_fg:-'#ffff00'} # yellow
  tx_t_window_status_bell_bg=${tx_t_window_status_bell_bg:-'default'}
  tx_t_window_status_bell_attr=${tx_t_window_status_bell_attr:-'blink,bold'}
  tmux setw -g window-status-bell-style "fg=$tx_t_window_status_bell_fg,bg=$tx_t_window_status_bell_bg,$tx_t_window_status_bell_attr"

  tx_t_window_status_last_fg=${tx_t_window_status_last_fg:-'#00afff'} # light blue
  tx_t_window_status_last_bg=${tx_t_window_status_last_bg:-'default'}
  tx_t_window_status_last_attr=${tx_t_window_status_last_attr:-'none'}
  tmux setw -g window-status-last-style "fg=$tx_t_window_status_last_fg,bg=$tx_t_window_status_last_bg,$tx_t_window_status_last_attr"

  # -- indicators

  tx_t_pairing=${tx_t_pairing:-'👓'}            # U+1F453
  tx_t_pairing_fg=${tx_t_pairing_fg:-'#e4e4e4'} # white
  tx_t_pairing_bg=${tx_t_pairing_bg:-'none'}
  tx_t_pairing_attr=${tx_t_pairing_attr:-'none'}

  tx_t_prefix=${tx_t_prefix:-'⌨'}             # U+2328
  tx_t_prefix_fg=${tx_t_prefix_fg:-'#e4e4e4'} # white
  tx_t_prefix_bg=${tx_t_prefix_bg:-'none'}
  tx_t_prefix_attr=${tx_t_prefix_attr:-'none'}

  tx_t_root=${tx_t_root:-'!'}
  tx_t_root_fg=${tx_t_root_fg:-'none'}
  tx_t_root_bg=${tx_t_root_bg:-'none'}
  tx_t_root_attr=${tx_t_root_attr:-'bold,blink'}

  # -- status left style

  tx_t_status_left=${tx_t_status_left-' ❐ #S '}
  tx_t_status_left_fg=${tx_t_status_left_fg:-'#000000,#e4e4e4,#e4e4e4'}  # black, white , white
  tx_t_status_left_bg=${tx_t_status_left_bg:-'#ffff00,#ff00af,#00afff'}  # yellow, pink, white blue
  tx_t_status_left_attr=${tx_t_status_left_attr:-'bold,none,none'}

  tx_t_status_left=$(echo "$tx_t_status_left" | sed \
    -e "s/#{pairing}/#[fg=$tx_t_pairing_fg]#[bg=$tx_t_pairing_bg]#[$tx_t_pairing_attr]#{?session_many_attached,$tx_t_pairing,}/g")

  tx_t_status_left=$(echo "$tx_t_status_left" | sed \
    -e "s/#{prefix}/#[fg=$tx_t_prefix_fg]#[bg=$tx_t_prefix_bg]#[$tx_t_prefix_attr]#{?client_prefix,$tx_t_prefix,}/g")

  tx_t_status_left=$(echo "$tx_t_status_left" | sed \
    -e "s%#{root}%#[fg=$tx_t_root_fg]#[bg=$tx_t_root_bg]#[$tx_t_root_attr]#(cut -c3- ~/.tmux.conf | sh -s _root #{pane_tty} #D)#[inherit]%g")

  if [ -n "$tx_t_status_left" ]; then
    status_left=$(awk \
                      -v fg_="$tx_t_status_left_fg" \
                      -v bg_="$tx_t_status_left_bg" \
                      -v attr_="$tx_t_status_left_attr" \
                      -v mainsep="$tx_t_left_separator_main" \
                      -v subsep="$tx_t_left_separator_sub" '
      function subsplit(s,   l, i, a, r)
      {
        l = split(s, a, ",")
        for (i = 1; i <= l; ++i)
        {
          o = split(a[i], _, "(") - 1
          c = split(a[i], _, ")") - 1
          open += o - c
          o_ = split(a[i], _, "{") - 1
          c_ = split(a[i], _, "}") - 1
          open_ += o_ - c_
          o__ = split(a[i], _, "[") - 1
          c__ = split(a[i], _, "]") - 1
          open__ += o__ - c__

          if (i == l)
            r = sprintf("%s%s", r, a[i])
          else if (open || open_ || open__)
            r = sprintf("%s%s,", r, a[i])
          else
            r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
        }

        gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
        return r
      }
      BEGIN {
        FS = "|"
        l1 = split(fg_, fg, ",")
        l2 = split(bg_, bg, ",")
        l3 = split(attr_, attr, ",")
        l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
      }
      {
        for (i = j = 1; i <= NF; ++i)
        {
          if (open || open_ || open__)
            printf "|%s", subsplit($i)
          else
          {
            if (i > 1)
              printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j_], bg[j], mainsep, fg[j], bg[j], attr[j], subsplit($i)
            else
              printf "#[fg=%s,bg=%s,%s]%s", fg[j], bg[j], attr[j], subsplit($i)
          }

          if (!open && !open_ && !open__)
          {
            j_ = j
            j = j % l + 1
          }
        }
        printf "#[fg=%s,bg=%s,none]%s", bg[j_], "default", mainsep
      }' << EOF
$tx_t_status_left
EOF
    )

    # are we running a tmux in between v1.9 and v2.0?
    if [ x"$(tmux -q -L tmux_theme_status_left_test -f /dev/null new-session -d \; show -g -v status-left \; kill-session)" = x"[#S] " ]; then
      case "$status_left" in
        *\ )
          ;;
        *)
          status_left="$status_left "
          ;;
      esac
    fi
  fi

  # -- status right style

  tx_t_status_right=${tx_t_status_right-'#{pairing}#{prefix} #{battery_status} #{battery_bar} #{battery_percentage} , %R , %d %b | #{username} | #{hostname} '}
  tx_t_status_right_fg=${tx_t_status_right_fg:-'#8a8a8a,#e4e4e4,#000000'} # light gray, white, black
  tx_t_status_right_bg=${tx_t_status_right_bg:-'#080808,#d70000,#e4e4e4'} # dark gray, red, white
  tx_t_status_right_attr=${tx_t_status_right_attr:-'none,none,bold'}

  tx_t_status_right=$(echo "$tx_t_status_right" | sed \
    -e "s/#{pairing}/#[fg=$tx_t_pairing_fg]#[bg=$tx_t_pairing_bg]#[$tx_t_pairing_attr]#{?session_many_attached,$tx_t_pairing,}/g")

  tx_t_status_right=$(echo "$tx_t_status_right" | sed \
    -e "s/#{prefix}/#[fg=$tx_t_prefix_fg]#[bg=$tx_t_prefix_bg]#[$tx_t_prefix_attr]#{?client_prefix,$tx_t_prefix,}/g")

  tx_t_status_right=$(echo "$tx_t_status_right" | sed \
    -e "s%#{root}%#[fg=$tx_t_root_fg]#[bg=$tx_t_root_bg]#[$tx_t_root_attr]#(cut -c3- ~/.tmux.conf | sh -s _root #{pane_tty} #D)#[inherit]%g")

  if [ -n "$tx_t_status_right" ]; then
    status_right=$(awk \
                      -v fg_="$tx_t_status_right_fg" \
                      -v bg_="$tx_t_status_right_bg" \
                      -v attr_="$tx_t_status_right_attr" \
                      -v mainsep="$tx_t_right_separator_main" \
                      -v subsep="$tx_t_right_separator_sub" '
      function subsplit(s,   l, i, a, r)
      {
        l = split(s, a, ",")
        for (i = 1; i <= l; ++i)
        {
          o = split(a[i], _, "(") - 1
          c = split(a[i], _, ")") - 1
          open += o - c
          o_ = split(a[i], _, "{") - 1
          c_ = split(a[i], _, "}") - 1
          open_ += o_ - c_
          o__ = split(a[i], _, "[") - 1
          c__ = split(a[i], _, "]") - 1
          open__ += o__ - c__

          if (i == l)
            r = sprintf("%s%s", r, a[i])
          else if (open || open_ || open__)
            r = sprintf("%s%s,", r, a[i])
          else
            r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
        }

        gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
        return r
      }
      BEGIN {
        FS = "|"
        l1 = split(fg_, fg, ",")
        l2 = split(bg_, bg, ",")
        l3 = split(attr_, attr, ",")
        l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
      }
      {
        for (i = j = 1; i <= NF; ++i)
        {
          if (open_ || open || open__)
            printf "|%s", subsplit($i)
          else
            printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j], (i == 1) ? "default" : bg[j_], mainsep, fg[j], bg[j], attr[j], subsplit($i)

          if (!open && !open_ && !open__)
          {
            j_ = j
            j = j % l + 1
          }
        }
      }' << EOF
$tx_t_status_right
EOF
    )
  fi

  # -- variables

  tmux set -g '@root' "$tx_t_root"

 case "$status_left $status_right" in
   *'#{username}'*|*'#{hostname}'*|*'#{username_ssh}'*|*'#{hostname_ssh}'*)
     status_left=$(echo "$status_left" | sed \
       -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_tty} false #D)%g' \
       -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_tty} false #D)%g' \
       -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_tty} true #D)%g' \
       -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_tty} true #D)%g')
     status_right=$(echo "$status_right" | sed \
       -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_tty} false #D)%g' \
       -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_tty} false #D)%g' \
       -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_tty} true #D)%g' \
       -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_tty} true #D)%g')
     ;;
 esac

 # status_left=$(echo "$status_left" | sed 's%#{ifstats}%#(cut -c3- ~/.tmux.conf | sh -s _ifstats)%g')
 status_right=$(echo "$status_right" | sed 's%#{ifstats}%#(cut -c3- ~/.tmux.conf | sh -s _ifstats)%g')

  case "$status_left $status_right" in
    *'#{uptime_d}'*|*'#{uptime_h}'*|*'#{uptime_m}'*)
      status_left=$(echo "$status_left" | sed -E \
        -e 's/#\{(\?)?uptime_d/#\{\1@uptime_d/g' \
        -e 's/#\{(\?)?uptime_h/#\{\1@uptime_h/g' \
        -e 's/#\{(\?)?uptime_m/#\{\1@uptime_m/g' \
        -e 's/#\{(\?)?uptime_s/#\{\1@uptime_s/g')
      status_right=$(echo "$status_right" | sed -E \
        -e 's/#\{(\?)?uptime_d/#\{\1@uptime_d/g' \
        -e 's/#\{(\?)?uptime_h/#\{\1@uptime_h/g' \
        -e 's/#\{(\?)?uptime_m/#\{\1@uptime_m/g' \
        -e 's/#\{(\?)?uptime_s/#\{\1@uptime_s/g')
      status_right="#(cut -c3- ~/.tmux.conf | sh -s _uptime)$status_right"
      ;;
  esac

  case "$status_left $status_right" in
    *'#{loadavg}'*)
      status_left=$(echo "$status_left" | sed -E \
        -e 's/#\{(\?)?loadavg/#\{\1@loadavg/g')
      status_right=$(echo "$status_right" | sed -E \
        -e 's/#\{(\?)?loadavg/#\{\1@loadavg/g')
      status_right="#(cut -c3- ~/.tmux.conf | sh -s _loadavg)$status_right"
      ;;
  esac

  status_left=$(echo "$status_left" | sed 's%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled_digit #S)%g')
  status_right=$(echo "$status_right" | sed 's%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled_digit #S)%g')

  tmux  set -g status-left-length 1000 \; set -g status-left "$status_left" \;\
        set -g status-right-length 1000 \; set -g status-right "$status_right"

  # -- clock -------------------------------------------------------------

  tx_t_clock_colour=${tx_t_clock_colour:-'#00afff'} # light blue
  tx_t_clock_style=${tx_t_clock_style:-'24'}
  tmux  setw -g clock-mode-colour "$tx_t_clock_colour" \;\
        setw -g clock-mode-style "$tx_t_clock_style"
}

_apply_configuration() {
  _apply_overrides
  _apply_bindings
  _apply_theme
  for name in $(printenv | grep -Eo '^tmux_conf_[^=]+'); do tmux setenv -gu "$name"; done;
}

_urlview() {
  tmux capture-pane -J -S - -E - -b "urlview-$1" -t "$1"
  tmux split-window "tmux show-buffer -b urlview-$1 | urlview || true; tmux delete-buffer -b urlview-$1"
}

_fpp() {
  tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
  tmux split-window "tmux show-buffer -b fpp-$1 | fpp || true; tmux delete-buffer -b fpp-$1"
}

"$@"
