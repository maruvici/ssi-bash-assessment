#!/usr/bin/bash

# DEPENDENCIES CHECK
bash ./dependencies.sh

# INPUT/PARAMETER VALIDATION
# Exit code 4 implies error due to invalid input
c_set=1
w_set=1
e_set=1

while getopts ":c:w:e:" param; do
    case $param in
        c) 
            crit_thresh=$OPTARG; c_set=0
            ;;
        w)
            warn_thresh=$OPTARG; w_set=0
            ;;
        e) 
            email=$OPTARG; e_set=0
            ;;
        :) 
            echo "Error: -$OPTARG requires an argument"; exit 4
            ;;
        \?)
            echo "Usage: bash cpu_check.sh -c argC -w argW -e argE"; exit 4
            ;;
    esac
done

PERCENTAGE_REGEX="^[0-9]+$"
EMAIL_REGEX="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"

if [ $(( $c_set + $w_set + $e_set )) -ne 0 ]; then
    echo "Usage: cpu_check.sh -c argC -w argW -e argE"; exit 4
elif ! [[ $crit_thresh =~ $PERCENTAGE_REGEX && $crit_thresh -le 100 && $crit_thresh -ge 0 ]]; then
    echo "Enter valid critical threshold percentage"; exit 4
elif ! [[ $warn_thresh =~ $PERCENTAGE_REGEX && $warn_thresh -le 100 && $warn_thresh -ge 0 ]]; then
    echo "Enter valid warning threshold percentage"; exit 4
elif [[ $warn_thresh -ge $crit_thresh ]]; then
    echo "Requirement: Critical Threshold ($crit_thresh) > Warning Threshold ($warn_thresh)"; exit 4
elif ! [[ $email =~ $EMAIL_REGEX ]]; then
    echo "Enter a valid email"; exit 4
fi

# CPU CHECK
IDLE_CPU_REGEX="s/.*, *\([0-9.]*\)%* id.*/\1/"
total_cpu_used=$( top -bn1 | grep "Cpu(s)" | sed "$IDLE_CPU_REGEX" | awk '{print 100 - $1}' )

if [[ $( echo "$total_cpu_used < $warn_thresh" | bc ) = 1 ]]; then
    exit 0
elif [[ $( echo "($total_cpu_used >= $warn_thresh) * ($total_cpu_used < $crit_thresh)" | bc ) = 1 ]]; then
    exit 1
elif [[ $(echo "($total_cpu_used >= $crit_thresh)" | bc ) = 1 ]]; then
    TMPREPORT=$(mktemp cpu_report.XXXXXX)
    subject="$(date +"%Y%m%d %H:%M ") cpu_check - critical"
    ps -eo pid,user,pcpu,time,comm --sort=-pcpu | head -n 11 | column -t > "$TMPREPORT"
    echo -e "CPU usage is now critical. Check attached CPU process report below" \
    | mailx -a "$TMPREPORT" -s "$subject" $email
    rm -f "$TMPREPORT"
    exit 2
fi
