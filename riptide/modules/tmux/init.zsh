
function ifstats {
  local tick=$(netstat -i -I en0 -b | grep -m 1 en0 | awk '{print $7,$10}')
  sleep 0.5
  local tock=$(netstat -i -I en0 -b | grep -m 1 en0 | awk '{print $7,$10}')

  echo $(echo $tick'\n'$tock | \
      awk '{i=$1-i; u=$2-u} END {print i / 128 / .5, u / 128 / .5}' | \
      awk '
        {for (i=1;i<=NF;i++) a[i] = sprintf("%2d%s",
          ($i > 1024) ? $i / 1024 : $i,
          ($i > 1024) ? "m" : "k")}
        END {printf "⎆ ↑ %s ↓ %s", a[1], a[2]}')
}
