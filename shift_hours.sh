#!/bin/bash
# - version 1.0
# - require cut, paste, awk, wc, date
#-----------------------------------------


#file_name='./test_time.log'
#new_filename='./new_logfile.log'

file_name=${1}  # source file
new_filename=${2}   # output file


# Shift setting
#-----------------------------------------
time_shift_direction='forward'  # use 'forward' or 'backward'
time_shift_hours=8
time_float_len=6
time_str_len=26
time_shirt_fmt="%Y-%m-%d %H:%M:%S.%${time_float_len}N"      # use dash 
#time_shirt_fmt="%Y/%m/%d %H:%M:%S.%${time_float_len}N"     # use slash 

timefile='/tmp/timefile'
new_timefile='/tmp/newtimefile'
no_timefile='/tmp/notimefile'


# function
#-----------------------------------------
function shift_hours() {

    rm -rf ${timefile} ${new_timefile} ${no_timefile}
    
    local file_name=${1}
    local offset_direction=${2}
    local offset_hours=${3}

    echo -e "\n[ Shift hours - ${offset_direction} ${offset_hours} hours. ]"
    echo "-----------------------------------------------------------"
    cat ${file_name} | cut -c-${time_str_len} > ${timefile}

    time_count=`wc -l ${timefile} | awk '{print $1}'`
    if [[ "${time_count}" -eq "0" ]]; then
        echo "Error, unable to parser date time in ${file_name}."
        exit
    else
        echo "Total ${time_count} date-time records collected."
    fi

    echo "Original Time: "
    echo "  First Time Record - " `head -n 1 ${timefile}`
    echo "  Last Time Record  - " `tail -n 1 ${timefile}`

    offset_seconds=$(( 3600 * offset_hours ))

    if [[ "${offset_direction}" == "forward" ]]; then
        math_symbol='+'          
    elif [[ "${offset_direction}" == "backward" ]]; then
        math_symbol='-'
    fi
       
    counter=0
    while read -r line
    do
        timestamp=`date -d "${line}" +%s.%${time_float_len}N`

        # ---------------------------------------
        # choose calculation tool you wanna use by uncomment the its code
        
        # (use bc)
        #timestamp=`echo ${timestamp} ${math_symbol} ${offset_seconds} | bc`

        # (use awk with 6 digits of float point)
        #timestamp=`echo "${timestamp} ${offset_seconds}" | awk '{printf ("%.6f\n", $1+$2)}'`

        # (use awk with configured float point length)
        awk_fmt='{printf ("%.'${time_float_len}'f\n", $1'${math_symbol}'$2)}'
        timestamp=`echo "${timestamp} ${offset_seconds}" | awk "${awk_fmt}"`

        # (use python, will miss some float)
        #timestamp=$(python -c "print ${timestamp}${math_symbol}${offset_seconds}")

        # (use perl)
        #timestamp=$(perl -e "print ${timestamp}+${offset_seconds}")

        # ---------------------------------------

        added_hours=`date -d "@${timestamp}" +"${time_shirt_fmt}"`
        echo $added_hours >> ${new_timefile}

        counter=$((counter+1))
        echo ${counter} > /tmp/shift_hours_line_count

    done < "${timefile}"

    
    echo "New Time(24 hour format): "
    echo "  First Time Record - " `head -n 1 ${new_timefile}`
    echo "  Last Time Record  - " `tail -n 1 ${new_timefile}`
    echo 

    # combin new time file and source log file
    cat ${file_name} | cut -c$((time_str_len+2))- > ${no_timefile}
    paste -d' ' ${new_timefile} ${no_timefile} > ${new_filename}

    echo
    echo "Shifted Log File: ${new_filename}"
    echo "  First line - "`head -n 1 ${new_filename}`
    echo "  Last Line  - "`tail -n 1 ${new_filename}`
}


# run
shift_hours ${file_name} ${time_shift_direction} ${time_shift_hours}




