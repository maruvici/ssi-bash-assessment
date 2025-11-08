#!/usr/bin/bash

# DEPENDENCIES CHECK
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash $SCRIPT_DIR/dependencies.sh

# INPUT/PARAMETER VALIDATION
# Exit code 4 implies error due to invalid input
c_set=1
w_set=1
e_set=1

while getopts ":c:w:e:" param; do
    case $param in
        c) 
            if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
                echo "Error: -$param requires an argument"; exit 4
            fi
            crit_thresh=$OPTARG; c_set=0
            ;;
        w)
            if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
                echo "Error: -$param requires an argument"; exit 4
            fi
            warn_thresh=$OPTARG; w_set=0
            ;;
        e) 
            if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
                echo "Error: -$param requires an argument"; exit 4
            fi
            email=$OPTARG; e_set=0
            ;;
        :) 
            echo "Error: -$OPTARG requires an argument"; exit 4
            ;;
        \?)
            echo "Usage: bash memory_check.sh -c argC -w argW -e argE"; exit 4
            ;;
    esac
done

PERCENTAGE_REGEX="^[0-9]+$"
EMAIL_REGEX="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"

if [ $(( $c_set + $w_set + $e_set )) -ne 0 ]; then
    echo "Usage: memory_check.sh -c argC -w argW -e argE"; exit 4
elif ! [[ $crit_thresh =~ $PERCENTAGE_REGEX && $crit_thresh -le 100 && $crit_thresh -gt 0 ]]; then
    echo "Enter valid critical threshold percentage"; exit 4
elif ! [[ $warn_thresh =~ $PERCENTAGE_REGEX && $warn_thresh -lt 100 && $warn_thresh -ge 0 ]]; then
    echo "Enter valid warning threshold percentage"; exit 4
elif [[ $warn_thresh -ge $crit_thresh ]]; then
    echo "Requirement: Critical Threshold ($crit_thresh) > Warning Threshold ($warn_thresh)"; exit 4
elif ! [[ $email =~ $EMAIL_REGEX ]]; then
    echo "Enter a valid email"; exit 4
fi

# MEMORY CHECK
total_memory=$( free | grep Mem: | awk '{print $2}' )
used_memory=$( free | grep Mem: | awk '{print $3 }' )
used_percentage=$( echo "scale=2; ($used_memory * 100) / $total_memory" | bc )

if [[ $( echo "$used_percentage < $warn_thresh" | bc ) = 1 ]]; then
    exit 0
elif [[ $( echo "($used_percentage >= $warn_thresh) * ($used_percentage < $crit_thresh)" | bc ) = 1 ]]; then
    exit 1
elif [[ $(echo "($used_percentage >= $crit_thresh)" | bc ) = 1 ]]; then
    TMPREPORT=$(mktemp mem_report.XXXXXX)
    subject="$(date +"%Y%m%d %H:%M ") mem_check - critical"
    ps -eo pid,user,pmem,time,comm --sort=-pmem | head -n 11 | column -t > "$TMPREPORT"
    echo -e "Memory usage is now critical. Check attached memory process report below" \
    | mailx -a "$TMPREPORT" -s "$subject" $email
    rm -f "$TMPREPORT"
    exit 2
fi
