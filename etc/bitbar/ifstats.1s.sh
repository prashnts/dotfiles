#!/bin/sh
export PATH=$PATH:/usr/local/bin
printf "↓%4s | font=FiraCode-Retina color=#2A9D8F" $(ifstat -bi en0 0.1 1 | tail -n 1 | \
    awk '
      {for (i=1;i<=NF;i++) a[i] = sprintf("%d%s",
        ($i > 1024) ? $i / 1024 : $i,
        ($i > 1024) ? "m" : "k")}
      END {print a[1]}')
