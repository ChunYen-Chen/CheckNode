#==============================================================================================================
# Array and variables
#==============================================================================================================
HOST=`hostname`
declare -A NODE_COUNT                        # Associative array to store the number of properties of the nodes.
declare -A JOB_LIST                          # Associative array to store the job id with user.
declare -A JOB_USER                          # Associative array to store the job user in each node`
declare -A JOB_TIME_M                        # Associative array to store the month of the job in each node`
declare -A JOB_TIME_D                        # Associative array to store the day   of the job in each node`
declare -A JOB_TIME_T                        # Associative array to store the time  of the job in each node`
WANTED=('name' 'state' 'properties' 'jobs')  # Wanted properties from the xml file.
WANTED_VAL=()                                # A temporary array to store the values from xml file.
N_WANTED=${#WANTED[@]}                       # Length of the wanted array.
BLANK=""



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


#==============================================================================================================
# Initialize
#==============================================================================================================
DIR=`sed "1q;d" config`
DIR=$(echo ${DIR} | awk '{print $2}')    # The directory of this file.
PRINT_FREE=false                         # Option "f": print the free nodes
PRINT_SHOWQ=false                        # Option "q": print the "showq"
PRINT_JOB=false                          # Option "j": print the job ID and the job user
PRINT_IDLE=false                         # Option "i": print the idle users
PRINT_TIME=false                         # Option "t": print the time of each job

# print free nodes
if [[ ${1} == *"f"* ]] ; then PRINT_FREE=true ; fi

# print the original showq
if [[ ${1} == *"q"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: We can only use 'q' option on eureka00.\n"${WHITE}
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
        printf ${RED}"ERROR: We can only use 'j' option on eureka00.\n"${WHITE}
    else
        PRINT_JOB=true
    fi
fi

# print the idle user jobs
if [[ ${1} == *"i"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: We can only use 'i' option on eureka00.\n"${WHITE}
    else
        PRINT_IDLE=true
    fi
fi

# print the start time
if [[ ${1} == *"t"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: We can only use 't' option on eureka00.\n"${WHITE}
    else
        PRINT_TIME=true
    fi
fi

# print all details
if [[ ${1} == *"a"* ]] ; then 
    if [[ $HOST != 'eureka00' ]] ; then
        printf ${RED}"ERROR: We can only use 'a' option on eureka00.\n"${WHITE}
    else
        PRINT_JOB=true
        PRINT_IDLE=true
        PRINT_TIME=true
    fi
fi



#==============================================================================================================
# Prepare needed data
#==============================================================================================================
# Get the statisic of the cluster in xml style.
pbsnodes -x > ${DIR}now_stat

if $PRINT_SHOWQ || $PRINT_JOB || $PRINT_IDLE || $PRINT_TIME ; then
    # Get the current job list
    showq > ${DIR}now_list 
    
    temp=`tail -n 1 ${DIR}now_list`
    temp=($temp)
    N_jobs_active=${temp[5]}
    N_jobs_idle=${temp[8]}
    
    for ((i=4; i<4+$N_jobs_active; i++))
    do 
      job=`sed "${i}q;d" ${DIR}now_list`
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

# only print the showq message
if $PRINT_SHOWQ ; then
    cat ${DIR}now_list 
    exit
fi

#==============================================================================================================
# Main print
#==============================================================================================================
# Header of the node 
printf "===============================================================================================\n"
printf "Name      State                      Label               "
if $PRINT_JOB  ; then printf "User            JobID  " ; fi
if $PRINT_TIME ; then printf "Start time     "         ; fi
printf "\n"
printf "===============================================================================================\n"

# loop all the properties one by one
while read_dom; do
    # Store the node properties.
    for (( i=0; i<$N_WANTED; i++))
    do 
        if [[ $ENTITY = ${WANTED[$i]} ]] ; then WANTED_VAL[$i]=$CONTENT ; fi
    done
    
    # If it the end of the node properties, print out the messages of the node.
    if [[ $ENTITY = "/Node" ]] ; then
        # only print free node
        if $PRINT_FREE ; then
            if [[ ${WANTED_VAL[1]} = "free" ]] ; then
                # 1. node name
                printf "%-10s" ${WANTED_VAL[0]}
                

                # 2. node status
                printf $GREEN"%-27s"$WHITE ${WANTED_VAL[1]}
                

                # 3. node properties
                if [[ ${WANTED_VAL[2]} = "unstableq" ]] ; then
                    printf $BLUE"%-20s"$WHITE ${WANTED_VAL[2]}
                else
                    printf "%-20s" ${WANTED_VAL[2]}
                fi
                printf "\n"
                
                # Count the number of properties.
                PROP=`sep_string ${WANTED_VAL[2]}`
                for name in $PROP ; do ((NODE_COUNT[$name]+=1)) ; done

            fi    # if [[ ${WANTED_VAL[1]} = "free" ]]
        # print all node
        else # if $PRINT_FREE
            # 1. node name
            printf "%-10s" ${WANTED_VAL[0]}
           

            # 2. node status
            if [[ ${WANTED_VAL[1]} = "free" ]] ; then
                printf $GREEN"%-27s"$WHITE ${WANTED_VAL[1]}
            elif [[ ${WANTED_VAL[1]} = "job-exclusive" ]] ; then
                printf $RED"%-27s"$WHITE ${WANTED_VAL[1]}
            else
                printf $RED"%-27s"$WHITE ${WANTED_VAL[1]}
            fi
           

            # 3. node properties
            if [[ ${WANTED_VAL[2]} = "unstableq" ]] ; then
                printf $BLUE"%-20s"$WHITE ${WANTED_VAL[2]}
            else
                printf "%-20s" ${WANTED_VAL[2]}
            fi
            
            # Count the number of properties.
            PROP=`sep_string ${WANTED_VAL[2]}`
            for name in $PROP ; do ((NODE_COUNT[$name]+=1)) ; done
           

            # 4. print user, job id, and time
            if $PRINT_JOB || $PRINT_TIME ; then
                temp=(${WANTED_VAL[3]})
                for i in "${!temp[@]}"
                do
                    temp="${temp[$i]#*/}"
                    JOB_ID="${temp%.eureka*}"
                    ((JOB_USER[${JOB_ID}]+=1))
                done
                
                if [[ ${#JOB_USER[@]} = "0" ]] ; then
                    printf "%-15s " $BLANK
                else
                    PRINTED=false
                    for i in "${!JOB_USER[@]}"
                    do
                        if $PRINTED ; then printf "\n %-56s"$BLANK ; fi
                        if $PRINT_JOB ; then printf "%-15s %-6s " ${JOB_LIST[$i]} $i ; fi
                        if $PRINT_TIME ; then
                            printf "%-3s %-2s %-10s " ${JOB_TIME_M[$i]} ${JOB_TIME_D[$i]} ${JOB_TIME_T[$i]}
                        fi
                        PRINTED=true
                    done
                fi
            fi    # if $PRINT_JOB || $PRINT_TIME

            printf "\n"
        
        fi # if $PRINT_FREE ; then ... else ...
        
        # Clear the array once it printed
        WANTED_VAL=() 
        unset JOB_USER
        declare -g JOB_USER
    
    fi # if [[ $ENTITY = "/Node" ]] ; then
    
    # Break the loop when it reach the end of the file.
    if [[ $ENTITY = "/Data" ]] ; then break ; fi

done < ${DIR}now_stat # while read_dom; do

printf "===============================================================================================\n"

# Print the number of each properties.
for i in "${!NODE_COUNT[@]}" ; do printf "%-12s " $i                ; done
printf "\n"
for i in "${!NODE_COUNT[@]}" ; do printf "%-12s " ${NODE_COUNT[$i]} ; done
printf "\n"

printf "===============================================================================================\n"

if $PRINT_IDLE ; then
    printf "===============================================================================================\n"
    printf "Idle User       JobID  Proc "
    if $PRINT_TIME ; then printf "Start time "; fi 
    printf "\n"
    printf "===============================================================================================\n"
    # Print the idle jobs
    for ((i=11+$N_jobs_active; i<11+$N_jobs_active+$N_jobs_idle; i++))
    do 
      job=`sed "${i}q;d" ${DIR}now_list`
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
