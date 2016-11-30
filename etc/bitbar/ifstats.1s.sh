#!/bin/sh
export PATH=$PATH:/usr/local/bin
# printf "↓%4s | font=FiraCode-Retina color=#2A9D8F" $(ifstat -bi en0 0.1 1 | tail -n 1 | \
#     awk '
#       {for (i=1;i<=NF;i++) a[i] = sprintf("%d%s",
#         ($i > 1000) ? $i / 1024 : $i,
#         ($i > 1000) ? "m" : "k")}
#       END {print a[1]}')

printf "↓%4s | font=FiraCode-Retina color=#%s" $(ifstat -bi en0 0.1 1 | tail -n 1 | \
    awk '
      {printf("%d%s %s",
        ($1 > 1000) ? $1 / 1024 : $1,
        ($1 > 1000) ? "m" : "k",
        ($1 > 1000) ? "A13D63" : \
          ($1 > 4000) ? "2A9D8F" : \
            ($1 > 2000) ? "A5C882" : "324376")
      }')
