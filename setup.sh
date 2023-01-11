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


WORK_DIR=`pwd`
# 1. write the working directory
printf "Would you like to user the current directory "$GREEN"(${WORK_DIR}/)"$WHITE" as the working directory?[y/n] "
read USE_PWD

if [[ "${USE_PWD}" = "y" || "$USE_PWD" = "Y" ]] ; then
    WORK_DIR=`pwd`
else
    printf "Notice: The working directory should have "$GREEN"check_node.sh"$WHITE" file inside.\n"
    read -p 'Your working directory: ' WORK_DIR
fi

# 2. add alias in .bashrc
printf "Would you like to add an alias to your "$GREEN".bashrc"$WHITE"?[y/n] "
read USE_ALIAS

if [[ "$USE_ALIAS" = "y" || "$USE_ALIAS" = "Y" ]] ; then
    COMMAND="alias node='sh ${WORK_DIR}/check_node.sh'"
    
    USER=`whoami`
    BASH_FILE="/home/${USER}/.bashrc"
    printf "We will add an alias at the bottom of the "$GREEN"${BASH_FILE}"$WHITE"\n"
fi


# 3. update the config
printf "=============================================================================\n"
printf $RED"Final check! "$WHITE"If the following information is correct, please type [Y] or [y].\n"
printf     "Working directory     : "$GREEN"${WORK_DIR}/"$WHITE"\n"
if [[ "$USE_ALIAS" = "y" || "$USE_ALIAS" = "Y" ]] ; then
    printf ".bashrc file location : "$GREEN"$BASH_FILE"$WHITE"\n"
fi
read CHECK


if [[ "$CHECK" = "y" || "$CHECK" = "Y" ]] ; then
    echo "directory    ${WORK_DIR}/" > ${WORK_DIR}config
    echo "#====================================================" >> ${BASH_FILE}
    echo "# This the command for checking the node information." >> ${BASH_FILE}
    echo $COMMAND >> ${BASH_FILE}
    echo "#====================================================" >> ${BASH_FILE}
else
    printf $RED"The setup is not complete!\n"$WHITE
    exit
fi

# 4. output the tutorial
echo "Thanks for using the checking node funcion! Here are some examples for you."
echo "1. List the nodes name, properties, and status."
echo "node"
echo "2. List with option."
echo "node f"
echo "3. List with multiple options. (The option order does not matter.)"
echo "node ij"
echo "To view more option, please read README."
