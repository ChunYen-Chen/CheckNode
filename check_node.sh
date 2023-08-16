#!/bin/bash
#==============================================================================================================
# This is the simple code for getting the cluster information without root.
#
# Source code : https://github.com/ChunYen-Chen/CheckNode
# Version     : 1.2.4
#
#==============================================================================================================



#==============================================================================================================
# Array and variables
#==============================================================================================================
HOST=`hostname`
USER=`whoami`
NODE_ID=${HOST:(-2)}
CLUSTER=${HOST::(-2)}
declare -A NODE_COUNT                             # Associative array to store the number of labels of the nodes.
declare -A JOB_LIST                               # Associative array to store the job id with user.
declare -A JOB_USER                               # Associative array to store the job user in each node`
declare -A JOB_TIME_M                             # Associative array to store the month of the job in each node`
declare -A JOB_TIME_D                             # Associative array to store the day   of the job in each node`
declare -A JOB_TIME_T                             # Associative array to store the time  of the job in each node`
WANTED=('name' 'state' 'properties' 'jobs' 'np' 'status')  # Wanted properties from the xml file.
WANTED_SPACE=(10 27 20 22 16)                     # Wanted properties print space.
WANTED_VAL=()                                     # A temporary array to store the values from xml file.
N_WANTED=${#WANTED[@]}                            # Length of the wanted array.
BLANK=""
BASE_LENGTH=$(( ${WANTED_SPACE[0]} + ${WANTED_SPACE[1]} + ${WANTED_SPACE[2]} ))
PRINT_LENGTH=$BASE_LENGTH
DEBUG=false
DOWN_NODE=()



#==============================================================================================================
# Colors: "\033[" + "<0 or 1, meaning normal or bold>;" + "<color code>" + "m"
#==============================================================================================================
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
ORANGE='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
GRAY='\033[37m'
WHITE='\033[39m'



#==============================================================================================================
# Functions
#==============================================================================================================
display_help() {
    # Help the user to use this script
    echo "The script to list the current cluster information of each node."
    echo
    echo "Usage: sh checknode.sh [arguments]"
    echo
    echo "Examples: "
    echo "1. sh checknode.sh -f"
    echo "2. sh checknode.sh -u chunyenc"
    echo "3. sh checknode.sh -ij"
    echo
    echo "Arguements: "
    echo "-h         : Display the help messages."
    echo "-v         : Display the version."
    echo "-d         : Only display the down nodes."
    echo "-f         : Only display the free nodes."
    echo "-o         : Only display the offline nodes."
    echo "-s <jobID> : Only display the specific job id."
    echo "* The following can only work on login node."
    echo "-a         : Equivalent to the options of 'bijt'."
    echo "-i         : Display the idle users at the bottom."
    echo "-b         : Display the blocked users at the bottom."
    echo "-j         : Display with the job ID and the job users of each node."
    echo "-q         : Display the message from 'showq'."
    echo "-t         : Display with the starting time information."
    echo "-u <user>  : Only display the specific user."
    echo "-l <label> : Only display the specific node label."
    echo
    echo "Note: "
    echo "1. The argument 'q' does not work with other arguments."
    echo "2. The order of the arguments does not matter. e.g. 'ij' is equivalent to 'ji'."
    echo
}

clean_exit () {
    # Remove the temporary files then exit
    if $DEBUG ; then exit ; fi
    rm "${temp_list}"
    rm "${temp_stat}"
    exit
}

clean_array() {
    # Reset the arrays
    WANTED_VAL=()
    unset JOB_USER
    declare -g JOB_USER
}

read_dom () {
    # Read the xml file to get the properties(ENTITY) and value(CONTENT).
    local IFS=\>
    read -d \< ENTITY CONTENT
}

sep_string () {
    # Separate the string by comma(,) symbol.
    local IFS=", "
    read -ra OUT <<< $1
    #echo ${OUT[*]}
    echo ${OUT[@]}
}

print_name () {
    # $1 : the name string
    printf "%-${WANTED_SPACE[0]}s" $1
}

print_status () {
    # $1 : the status string
    # $2 : the number of used processor
    # $3 : the number of total processor

    OUT_STRING=$1

    if [[ $1 = "free" ]] ; then
        if [[ $2 = $3 ]] ; then
            printf $GREEN
        else
            printf $ORANGE
            OUT_STRING=`printf "%-4s(%02d/%02d)" $1 $2 $3`
        fi
    elif [[ $1 = "job-exclusive" ]] ; then
        printf $RED
    else
        printf $RED
    fi
    printf "%-${WANTED_SPACE[1]}s" $OUT_STRING
    printf $WHITE
}

print_labels () {
    # $1 : the label string
    if [[ $1 = "unstableq" ]] ; then printf $BLUE ; fi
    printf "%-${WANTED_SPACE[2]}s" $1
    printf $WHITE
}

print_job () {
    # $1 : the job user
    # $2 : the job ID
    printf "%-15s %-7s" $1 $2
}

print_time () {
    # $1 : the job start month
    # $2 : the job start day
    # $3 : the job start time
    printf "%-3s %-2s %-9s" $1 $2 $3
}

print_separate_line () {
    # $1 : the length of separate line
    for ((i=0; i<$1; i++))
    do
        printf "="
    done
    printf "\n"
}



#==============================================================================================================
# Initialize
#==============================================================================================================
DIR=$0
DIR=${DIR%"check_node.sh"}                # The directory of this file.
PRINT_FREE=false                          # Option "f": print the free nodes
PRINT_DOWN=false                          # Option "d": print the down nodes
PRINT_OFF=false                           # Option "o": print the offline nodes
PRINT_SHOWQ=false                         # Option "q": print the "showq"
PRINT_JOB=false                           # Option "j": print the job ID and the job user
PRINT_IDLE=false                          # Option "i": print the idle users
PRINT_BLOCK=false                         # Option "b": print the blocked users
PRINT_TIME=false                          # Option "t": print the time of each job
PRINT_SEL_ID=false                        # Option "s": print the selected id
PRINT_SEL_USER=false                      # Option "u": print the selected user
PRINT_SEL_LABEL=false                     # Option "l": print the selected label


# Get the options
while getopts ":hvadfoibjtqu:s:l:" option; do

    case $option in
        h) # display Help
            display_help
            exit
            ;;
        v) # display version
            echo "CheckNode 1.2.4"
            exit
            ;;
        a) # print all details
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'a' is only supported on login node.\n"${WHITE}
            else
                PRINT_JOB=true
                PRINT_IDLE=true
                PRINT_BLOCK=true
                PRINT_TIME=true
            fi
            ;;
        d) # print down nodes
            PRINT_DOWN=true
            ;;
        f) # print free nodes
            PRINT_FREE=true
            ;;
        o) # print free nodes
            PRINT_OFF=true
            ;;
        i) # print the idle user jobs
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'i' is only supported on login node.\n"${WHITE}
            else
                PRINT_IDLE=true
            fi
            ;;
        b) # print the blocked user jobs
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'b' is only supported on login node.\n"${WHITE}
            else
                PRINT_BLOCK=true
            fi
            ;;
        j) # print the jobs of each node
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'j' is only supported on login node.\n"${WHITE}
            else
                PRINT_JOB=true
            fi
            ;;
        t) # print the start time
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 't' is only supported on login node.\n"${WHITE}
            else
                PRINT_TIME=true
            fi
            ;;
        q) # print the original showq
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'q' is only supported on login node.\n"${WHITE}
            else
                PRINT_SHOWQ=true
            fi
            ;;
        u) # select sepcific user
            if [[ $NODE_ID != '00' ]] ; then
                printf ${RED}"ERROR: The option 'u' is only supported on login node.\n"${WHITE}
            else
                PRINT_SEL_USER=true
                SEL_USER="$OPTARG"
            fi
            ;;
        s) # select sepcific job id
            PRINT_SEL_ID=true
            SEL_ID="$OPTARG"
            ;;
        l) # select sepcific node label
            PRINT_SEL_LABEL=true
            SEL_LABEL="$OPTARG"
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit
            ;;
    esac
done   # while getopts

# The temporary files to store the output from the `pbsnodes` and `showq`.
temp_list=$(mktemp /tmp/list_${USER}.XXXXX)
#exec 3>"${temp_list}"
#exec 4<"${temp_list}"

temp_stat=$(mktemp /tmp/stat_${USER}.XXXXX)
#exec 5>"${temp_stat}"
#exec 6<"${temp_stat}"

# count the separate line length
if $PRINT_JOB  ; then ((PRINT_LENGTH+=${WANTED_SPACE[3]})) ; fi
if $PRINT_TIME ; then ((PRINT_LENGTH+=${WANTED_SPACE[4]})) ; fi

# to match the minmum length of the node labels
if [[ $PRINT_LENGTH -lt 61 ]] ; then PRINT_LENGTH=61 ; fi


# if debug mode overwrite the "temp_list" and "temp_stat"
if $DEBUG ; then
    temp_list="now_list"
    temp_stat="now_stat"
fi



#==============================================================================================================
# Prepare needed data
#==============================================================================================================
# Get the statisic of the cluster in xml style.
if ! $DEBUG ; then pbsnodes -x > ${temp_stat} ; fi

if $PRINT_SHOWQ || $PRINT_JOB || $PRINT_IDLE || $PRINT_BLOCK || $PRINT_TIME || $PRINT_SEL_USER ; then
    # Get the current job list
    if ! $DEBUG ; then showq > ${temp_list} ; fi

    # only print the showq message
    if $PRINT_SHOWQ ; then
        if $PRINT_FREE || $PRINT_JOB || $PRINT_IDLE || $PRINT_TIME ; then
            printf ${RED}"WARNING: We will only print out the content of 'showq'.\n"${WHITE}
        fi
        cat ${temp_list}
        clean_exit
    fi

    temp=`tail -n 1 ${temp_list}`
    temp=($temp)
    N_jobs_active=${temp[5]}
    N_jobs_idle=${temp[8]}
    N_jobs_block=${temp[11]}

    for ((i=4; i<4+$N_jobs_active; i++))
    do
      job=`sed "${i}q;d" ${temp_list}`
      job=($job)
      ID=(${job[0]})
      NAME=(${job[1]})
      MONTH=(${job[6]})
      DAY=(${job[7]})
      TIME=(${job[8]})
      JOB_LIST[$ID]=$NAME
      JOB_TIME_M[$ID]=$MONTH
      JOB_TIME_D[$ID]=$DAY
      JOB_TIME_T[$ID]=$TIME
    done
fi




#==============================================================================================================
# Main print
#==============================================================================================================
# Header of the node
print_separate_line $PRINT_LENGTH
printf "Name      Status                     Label               "
if $PRINT_JOB  ; then printf "User            JobID  " ; fi
if $PRINT_TIME ; then printf "Start time     "         ; fi
printf "\n"
print_separate_line $PRINT_LENGTH

# loop all the properties one by one
while read_dom; do
    # Store the node properties.
    for (( i=0; i<$N_WANTED; i++))
    do
        if [[ $ENTITY = ${WANTED[$i]} ]] ; then WANTED_VAL[$i]=$CONTENT ; fi
    done

    # If it the end of the node properties, print out the messages of the node.
    if [[ $ENTITY = "/Node" ]] ; then
        # separate the node status
        STAT=`sep_string ${WANTED_VAL[1]}`

        # check if the node is down
        down=0
        for name in $STAT
        do
            if [[ $name == "down" ]]; then ((down+=1)); fi
            if [[ $name == "offline" ]]; then ((down-=1)); fi
            if [[ ${WANTED_VAL[0]} == "${CLUSTER}00" ]]; then ((down-=1)); fi
        done
        if [[ $down -eq 1 ]]; then DOWN_NODE+=(${WANTED_VAL[0]}); fi

        #The message on the cluster
        MSG=`awk -F',' '{ for( i=1; i<=NF; i++ ) print $i }' <<<"${WANTED_VAL[5]}" | grep message`

        # only print the selected status
        if $PRINT_FREE || $PRINT_DOWN || $PRINT_OFF; then
            PRINT=false
            for name in $STAT
            do
                if $PRINT_FREE && [[ $name == "free" ]] ; then PRINT=true ; fi
                if $PRINT_DOWN && [[ $name == "down" ]] ; then PRINT=true ; fi
                if $PRINT_OFF  && [[ $name == "offline" ]] ; then PRINT=true ; fi
            done

            if ! $PRINT ; then clean_array ; continue ; fi

        fi

        # count the number of jobs on the node and number of processor is free
        N_PROC=${WANTED_VAL[4]}
        temp=(${WANTED_VAL[3]})
        for i in "${!temp[@]}"
        do
            temp2="${temp[$i]#*/}"
            JOB_ID="${temp2%.$CLUSTER*}"
            ((JOB_USER[${JOB_ID}]+=1))
            ((N_PROC-=1))
        done

        # separate the node labels
        PROP=`sep_string ${WANTED_VAL[2]}`

        # only print the selected label
        if $PRINT_SEL_LABEL ; then
            PRINT=false
            for name in $PROP
            do
                if [[ $SEL_LABEL == $name ]] ; then PRINT=true ; fi
            done

            if ! $PRINT ; then clean_array ; continue ; fi

        fi

        # only print the selected user or job id
        if $PRINT_SEL_ID ; then
            PRINT=false
            for i in "${!JOB_USER[@]}"
            do
                if [[ "$SEL_ID" == "$i" ]] ; then PRINT=true ; fi
            done

            if ! $PRINT ; then clean_array ; continue ; fi
        fi

        if $PRINT_SEL_USER ; then
            PRINT=false
            for i in "${!JOB_USER[@]}"
            do
                if [[ $SEL_USER == ${JOB_LIST[$i]} ]] ; then PRINT=true ; fi
            done

            if ! $PRINT ; then clean_array ; continue ; fi
        fi

        # 1. node name
        print_name ${WANTED_VAL[0]}

        # 2. node status
        print_status ${WANTED_VAL[1]} $N_PROC ${WANTED_VAL[4]}

        # 3. node labels
        print_labels ${WANTED_VAL[2]}

        # 4. print user, job id, and time
        if $PRINT_JOB || $PRINT_TIME ; then
            if [[ ${#JOB_USER[@]} = "0" ]] ; then
                if $PRINT_JOB  ; then printf "%-23s" $BLANK ; fi
                if $PRINT_TIME ; then printf "%-16s" $BLANK ; fi
            else
                PRINTED=false
                for i in "${!JOB_USER[@]}"
                do
                    if $PRINT_SEL_USER && [[ $SEL_USER != ${JOB_LIST[$i]} ]] ; then continue ; fi
                    if $PRINT_SEL_ID   && [[ $SEL_ID   != $i              ]] ; then continue ; fi
                    if $PRINTED ; then printf "\n%-${BASE_LENGTH}s" $BLANK ; fi
                    if $PRINT_JOB ; then print_job ${JOB_LIST[$i]} $i ; fi
                    if $PRINT_TIME ; then
                        print_time ${JOB_TIME_M[$i]} ${JOB_TIME_D[$i]} ${JOB_TIME_T[$i]}
                    fi
                    PRINTED=true
                done
            fi
        fi    # if $PRINT_JOB || $PRINT_TIME

        # print out the message on the cluster
        printf ${RED}"${MSG}"${WHITE}

        printf "\n"

        # count the number of labels.
        for name in $PROP ; do ((NODE_COUNT[$name]+=1)) ; done

        # clear the array once it printed
        clean_array

    fi # if [[ $ENTITY = "/Node" ]] ; then

    # Break the loop when it reach the end of the file.
    if [[ $ENTITY = "/Data" ]] ; then break ; fi

done < ${temp_stat} # while read_dom; do

# Print the number of each labels.
print_separate_line $PRINT_LENGTH
printf "Node Statistic\n"
print_separate_line $PRINT_LENGTH

for i in "${!NODE_COUNT[@]}" ; do printf "%-12s " $i                ; done
printf "\n"
for i in "${!NODE_COUNT[@]}" ; do printf "%-12s " ${NODE_COUNT[$i]} ; done
printf "\n"

print_separate_line $PRINT_LENGTH

# Print the idle jobs
if $PRINT_IDLE ; then
    print_separate_line $PRINT_LENGTH
    printf "Idle User       JobID  Proc "
    if $PRINT_TIME ; then printf "Start time "; fi
    printf "\n"
    print_separate_line $PRINT_LENGTH

    for ((i=11+$N_jobs_active; i<11+$N_jobs_active+$N_jobs_idle; i++))
    do
      job=`sed "${i}q;d" ${temp_list}`
      job=($job)
      ID=(${job[0]})
      NAME=(${job[1]})
      PROC=(${job[3]})
      MONTH=(${job[6]})
      DAY=(${job[7]})
      TIME=(${job[8]})

      if $PRINT_SEL_USER && [[ $SEL_USER != $NAME ]] ; then continue ; fi
      if $PRINT_SEL_ID   && [[ $SEL_ID   != $ID   ]] ; then continue ; fi
      printf "%-15s %-6s %-4s " $NAME $ID $PROC
      if $PRINT_TIME ; then printf "%-3s %-2s %-10s " $MONTH $DAY $TIME ; fi
      printf "\n"

    done
fi   # if $PRINT_IDLE

# Print the blocked jobs
if $PRINT_BLOCK ; then
    print_separate_line $PRINT_LENGTH
    printf "Blocked User    JobID  Proc "
    if $PRINT_TIME ; then printf "Start time "; fi
    printf "\n"
    print_separate_line $PRINT_LENGTH

    for ((i=17+$N_jobs_active+$N_jobs_idle; i<17+$N_jobs_active+$N_jobs_idle+$N_jobs_block; i++))
    do
      job=`sed "${i}q;d" ${temp_list}`
      job=($job)
      ID=(${job[0]})
      NAME=(${job[1]})
      PROC=(${job[3]})
      MONTH=(${job[6]})
      DAY=(${job[7]})
      TIME=(${job[8]})

      if $PRINT_SEL_USER && [[ $SEL_USER != $NAME ]] ; then continue ; fi
      if $PRINT_SEL_ID   && [[ $SEL_ID   != $ID   ]] ; then continue ; fi
      printf "%-15s %-6s %-4s " $NAME $ID $PROC
      if $PRINT_TIME ; then printf "%-3s %-2s %-10s " $MONTH $DAY $TIME ; fi
      printf "\n"

    done
fi   # if $PRINT_BLOCK

# Print out the down nodes
if [[ ${#DOWN_NODE[@]} -ne 0 ]]; then
    down_msg=""

    for node in "${DOWN_NODE[@]}"
    do
        down_msg="${down_msg}${node} "
    done

    printf "The node(s): "
    echo -e -n "\033[5;7m${down_msg:0:-1}\033[0m"
    printf " is(are) down. Please inform Wei-Hsuan Tzeng or send a message to slack.\n"
fi

clean_exit
#exec 3>&-
#exec 5>&-
