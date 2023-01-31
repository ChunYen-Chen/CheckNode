#==============================================================================================================
# Array and variables
#==============================================================================================================
HOST=`hostname`
USER=`whoami`
declare -A NODE_COUNT                             # Associative array to store the number of properties of the nodes.
declare -A JOB_LIST                               # Associative array to store the job id with user.
declare -A JOB_USER                               # Associative array to store the job user in each node`
declare -A JOB_TIME_M                             # Associative array to store the month of the job in each node`
declare -A JOB_TIME_D                             # Associative array to store the day   of the job in each node`
declare -A JOB_TIME_T                             # Associative array to store the time  of the job in each node`
WANTED=('name' 'state' 'properties' 'jobs' 'np')  # Wanted properties from the xml file.
WANTED_SPACE=(10 27 20 22 16)
WANTED_VAL=()                                     # A temporary array to store the values from xml file.
N_WANTED=${#WANTED[@]}                            # Length of the wanted array.
BLANK=""
BASE_LENGTH=$(( ${WANTED_SPACE[0]} + ${WANTED_SPACE[1]} + ${WANTED_SPACE[2]} ))
PRINT_LENGTH=$BASE_LENGTH



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
    echo "Usage: sh checknode.sh [a|f|i|j|q|t] [-h]"
    echo 
    echo "Examples: "
    echo "1. sh checknode.sh f"
    echo "2. sh checknode.sh ij"
    echo 
    echo "Arguements and Options: "
    echo "-h : Display the help messages."
    echo "a  : Equivalent to the options of 'ijt'."
    echo "f  : Only display the free nodes."
    echo "i  : Display the idle users at the bottom."
    echo "j  : Display with the job ID and the job users of each node."
    echo "q  : Display the message from 'showq'."
    echo "t  : Display with the starting time information."
    echo 
    echo "Note: "
    echo "1. The option 'q' does not work with other options."
    echo "2. The option 'q' can only work on 'eureka00'."
    echo "3. The order of the options does not matter. e.g. 'ij' is equivalent to 'ji'."
    echo 
}

clean_exit () {
    # Remove the temporary files then exit
    rm "${temp_list}"
    rm "${temp_stat}"
    exit
}

read_dom () {
    # Read the xml file to get the properties(ENTITY) and value(CONTENT).
    local IFS=\>
    read -d \< ENTITY CONTENT
}

sep_string () {
    # Separate the string by comma(,) symbol.
    local IFS=","
    read -ra OUT <<< $1
    echo ${OUT[*]}
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

print_properties () {
    # $1 : the properties string
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
# Get the options
while getopts ":h" option; do
    case $option in
        h) # display Help
            display_help
            exit;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done


DIR=$0
DIR=${DIR%"check_node.sh"}                # The directory of this file.
PRINT_FREE=false                          # Option "f": print the free nodes
PRINT_SHOWQ=false                         # Option "q": print the "showq"
PRINT_JOB=false                           # Option "j": print the job ID and the job user
PRINT_IDLE=false                          # Option "i": print the idle users
PRINT_TIME=false                          # Option "t": print the time of each job


# The temporary files to store the output from the `pbsnodes` and `showq`.
temp_list=$(mktemp /tmp/list_${USER}.XXXXX)
#exec 3>"${temp_list}"
#exec 4<"${temp_list}"

temp_stat=$(mktemp /tmp/stat_${USER}.XXXXX)
#exec 5>"${temp_stat}"
#exec 6<"${temp_stat}"


# print free nodes
if [[ ${1} == *"f"* ]] ; then PRINT_FREE=true ; fi

# print the original showq
if [[ ${1} == *"q"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: The option 'q' is only supported on eureka00.\n"${WHITE}
    else
        if [[  ${1} != "q" ]] ; then
            printf ${RED}"WARNING: We will only print out the content of 'showq'.\n"${WHITE}
        fi
        PRINT_SHOWQ=true
    fi
fi

# print the jobs of each node 
if [[ ${1} == *"j"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: The option 'j' is only supported on eureka00.\n"${WHITE}
    else
        PRINT_JOB=true
        ((PRINT_LENGTH+=${WANTED_SPACE[3]}))
    fi
fi

# print the idle user jobs
if [[ ${1} == *"i"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: The option 'i' is only supported on eureka00.\n"${WHITE}
    else
        PRINT_IDLE=true
    fi
fi

# print the start time
if [[ ${1} == *"t"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: The option 't' is only supported on eureka00.\n"${WHITE}
    else
        PRINT_TIME=true
        ((PRINT_LENGTH+=${WANTED_SPACE[4]}))
    fi
fi

# print all details
if [[ ${1} == *"a"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: The option 'a' is only supported on eureka00.\n"${WHITE}
    else
        PRINT_JOB=true
        PRINT_IDLE=true
        PRINT_TIME=true
        ((PRINT_LENGTH+=${WANTED_SPACE[3]}))
        ((PRINT_LENGTH+=${WANTED_SPACE[4]}))
    fi
fi

# to match the length of the node properties
if [[ $PRINT_LENGTH < 61 ]] ; then PRINT_LENGTH=61 ; fi



#==============================================================================================================
# Prepare needed data
#==============================================================================================================
# Get the statisic of the cluster in xml style.
pbsnodes -x > ${temp_stat}

if $PRINT_SHOWQ || $PRINT_JOB || $PRINT_IDLE || $PRINT_TIME ; then
    # Get the current job list
    showq > ${temp_list}

    # only print the showq message
    if $PRINT_SHOWQ ; then cat ${temp_list} ; clean_exit; fi
    
    temp=`tail -n 1 ${temp_list}`
    temp=($temp)
    N_jobs_active=${temp[5]}
    N_jobs_idle=${temp[8]}
    
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
printf "Name      State                      Label               "
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
        # only print free node when option f
        if $PRINT_FREE && [[ ${WANTED_VAL[1]} != "free" ]] ; then 
            WANTED_VAL=() 
            continue
        fi
        
        # count the number of jobs on the node and number of processor is free
        N_PROC=${WANTED_VAL[4]}
        temp2=(${WANTED_VAL[3]})
        for i in "${!temp2[@]}"
        do
            temp="${temp2[$i]#*/}"
            JOB_ID="${temp%.eureka*}"
            ((JOB_USER[${JOB_ID}]+=1))
            ((N_PROC-=1))
        done
        
        # 1. node name
        print_name ${WANTED_VAL[0]}

        # 2. node status
        print_status ${WANTED_VAL[1]} $N_PROC ${WANTED_VAL[4]}

        # 3. node properties
        print_properties ${WANTED_VAL[2]}
        
        # Count the number of properties.
        PROP=`sep_string ${WANTED_VAL[2]}`
        for name in $PROP ; do ((NODE_COUNT[$name]+=1)) ; done

        # 4. print user, job id, and time
        if $PRINT_JOB || $PRINT_TIME ; then
            if [[ ${#JOB_USER[@]} = "0" ]] ; then
                printf "%-1s" $BLANK
            else
                PRINTED=false
                for i in "${!JOB_USER[@]}"
                do
                    if $PRINTED ; then printf "\n%-${BASE_LENGTH}s" $BLANK ; fi
                    if $PRINT_JOB ; then print_job ${JOB_LIST[$i]} $i ; fi
                    if $PRINT_TIME ; then
                        print_time ${JOB_TIME_M[$i]} ${JOB_TIME_D[$i]} ${JOB_TIME_T[$i]}
                    fi
                    PRINTED=true
                done
            fi
        fi    # if $PRINT_JOB || $PRINT_TIME

        printf "\n"
        
        # clear the array once it printed
        WANTED_VAL=() 
        unset JOB_USER
        declare -g JOB_USER

    fi # if [[ $ENTITY = "/Node" ]] ; then
    
    # Break the loop when it reach the end of the file.
    if [[ $ENTITY = "/Data" ]] ; then break ; fi

done < ${temp_stat} # while read_dom; do

# Print the number of each properties.
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

      printf "%-15s %-6s %-4s " $NAME $ID $PROC
      if $PRINT_TIME ; then printf "%-3s %-2s %-10s " $MONTH $DAY $TIME ; fi
      printf "\n"
    
    done
fi   # if $PRINT_IDLE

clean_exit
#exec 3>&-
#exec 5>&-

