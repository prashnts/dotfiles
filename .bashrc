# .bashrc

# User specific aliases and functions
alias mysqlcli='/Applications/xampp/xamppfiles/bin/mysql -u root -p'
alias xampp='sudo /Applications/xampp/xamppfiles/xampp'
alias servedir='sudo python3 -m http.server'
alias cls='clear'
alias repo='cd ~/Repository/'
alias gitdir='cd ~/Repository/GIT/'
alias IP='ifconfig en0 | grep "inet" | grep -v "inet6" |
	  grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1'
alias commit='git commit --all -m '
alias gem='sudo gem'
alias howhotami='istats cpu temp | grep -o "[0-9\.]\+" | head -n 1'
alias howfastami='istats fan speed | grep -o "[0-9\.]\+" | tail -n 5 | head -n 1'
alias la='ls -a'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

function stats {
  echo "Prashant's MacBook. Running at $(tput setaf 6)$(howhotami)$(tput sgr0) °C, $(tput setaf 6)$(howfastami)$(tput sgr0) RPM"
  echo "$(tput setaf 3)IP:  $(tput setaf 6)$(IP)$(tput sgr0)"
  echo "$(tput setaf 3)Use: $(tput setaf 7)servedir PORT$(tput sgr0) to Serve Directory."
  echo "$(tput setaf 3)     $(tput setaf 7)gitdir$(tput sgr0) to reach the Git Repository."
  echo ""
}

function sleepy {
    time_now=`date +%s`;
    time_factor=`echo 5400`;
    time_first=`echo 840`;
    echo "If you head to bed now, you should try to wake up at:"
    for i in `seq 1 6`; do
        if [ $i == '1' ]; then 
            let time_out=$time_now+$time_factor+$time_first
            printf "%s" $(date -r $time_out +%H:%M\ HRS\ )
        else
            let time_out=$time_now+$i*$time_factor+$time_first
            printf "%s" $(date -r $time_out +%H:%M\ HRS\ );
        fi
        if [ $i == '6' ]; then
            printf "\n"
        else
            printf ", "
        fi
    done
}


stats;
sleepy;
