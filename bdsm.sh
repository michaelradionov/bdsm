#!/bin/bash

# BDSM – Bash Database SQL Manager
# https://github.com/michaelradionov/bdsm


SCRIPT_NAME="bdsm"

# Colors
L_RED='\033[1;31m'
L_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
D_GREY='\033[1;30m'
D_VIOL='\033[1;34m'
NC='\033[0m'

# Check previous command error status
check_command_exec_status () {
  if [[ $1 -eq 0 ]]
    then
      echo -e "${YELLOW}Success!${NC}"
      echo
  else
    echo -e "${L_RED}ERROR${NC}"
    echo
  fi
}

isDumpExists(){
# If dump soesn't exists
    if [ ! -f "$dbfile" ]; then
        echo -e "${L_RED}No DB dump file found!${NC}"
        return 1
    fi
}

# Deletes dump
deleteDump(){
   echo
  isDumpExists || return
  echo "Deleting dump...";
  rm -f $dbfile
  check_command_exec_status $?
}

# Imports dump
importDump(){
  isDumpExists || return
  echo "Importing...";
  mysql -u$DB_USERNAME -p$DB_PASSWORD -h$DB_HOST $DB_DATABASE --force < ./$dbfile
  check_command_exec_status $?
}

# Look for dump
FindDump(){
  read -p "Enter dump's path (type path to dump, q to exit): " enterDump
  case $enterDump in
    'q' )
    return
      ;;
    *)
    if [[ -f "$enterDump" ]]; then
      echo -e "Ok, I found it. Will look here in next operations."
      dbfile=$enterDump
    else
      echo -e "${L_RED}Can't find it!${NC}"
    fi
    ;;
  esac
}

# Enter credentials manually
EnterCredentials(){
      read -p "Enter Mysql hos: " DB_HOST
      read -p "Enter DB name: " DB_DATABASE
      read -p "Enter DB user: " DB_USERNAME
      read -p "Enter DB password: " DB_PASSWORD
}

# Forget credentials and dump
ForgetEverything(){
    unset dbfile
    unset DB_DATABASE
    unset DB_USERNAME
    unset DB_PASSWORD
}

# Searches in DB dump
SearchInDump(){
    echo
    isDumpExists || return
    read -p 'Search string: ' old_domain
    echo
    echo -e "Searching for ${WHITE}${old_domain}${NC} in ${WHITE}${dbfile}${NC}";
    find=`grep -o "$old_domain" "$dbfile" | wc -l | tr -d " "`;
    check_command_exec_status $?
    echo -e "Found ${WHITE}$find${NC} occurrences of $old_domain";
    echo
}

# Search and replace in dump
searchReplaceInDump(){
  SearchInDump
  echo
  isDumpExists || return
  read -p 'Replace string: ' new_domain
  echo
  echo -e "Replacing ${WHITE}${old_domain}${NC} with ${WHITE}${new_domain}${NC} in ${WHITE}${dbfile}${NC}";

   perl -pi -w -e "s|${old_domain}|${new_domain}|g;" "$dbfile"
   check_command_exec_status $?
}

# get DB credentials from config file
getCredentials(){

unset configFile
#    unset DB_DATABASE
#    unset DB_USERNAME
#    unset DB_PASSWORD

# Looking for config file
# WordPress
  if [ -f wp-config.php ]; then
      appName='WordPress'
      configFile=wp-config.php
      DB_HOST=`cat "$configFile" | grep DB_HOST | cut -d \' -f 4`
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWORD | cut -d \' -f 4`

# WordPress from wp-content. Long story. We have some oldest repos in wp-content folder
  elif [ -f ../wp-config.php ]; then
      appName='WordPress'
      configFile=../wp-config.php
      DB_HOST=`cat "$configFile" | grep DB_HOST | cut -d \' -f 4`
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWORD | cut -d \' -f 4`

# Laravel
  elif [[ -f .env ]]; then
      appName='Laravel'
      configFile=.env
      source .env

# Prestashop 1.7
  elif [[ -f app/config/parameters.php ]]; then
      appName='Prestashop 1.7'
      configFile=app/config/parameters.php
      DB_DATABASE=`cat "$configFile" | grep database_name | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep database_user | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep database_password | cut -d \' -f 4`

# Prestashop 1.6
  elif [[ -f config/settings.inc.php ]]; then
      appName='Prestashop 1.6'
      configFile=config/settings.inc.php
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWD | cut -d \' -f 4`

# Not found
#  else
#    DB_DATABASE=''
#    DB_USERNAME=''
#    DB_PASSWORD=''
  fi

}

# Creates DB dump
createDump(){
  echo
  if [[ -z $DB_DATABASE ]]; then
     echo -e "${L_RED}Can't find neither wp-config.php nor .env in current directory${NC}"
     return
  fi
  echo "Making DB dump...";
  mysqldump -u$DB_USERNAME -p$DB_PASSWORD -h$DB_HOST $DB_DATABASE > ./$DB_DATABASE.sql
  dbfile="$DB_DATABASE.sql"
  check_command_exec_status $?
#    This is for dumpStats
  remote=1
}

showCredentials(){
  echo
  echo -e "DB host: ${WHITE}$DB_HOST${NC}"
  echo -e "DB name: ${WHITE}$DB_DATABASE${NC}"
  echo -e "DB user: ${WHITE}$DB_USERNAME${NC}"
  echo -e "DB password: ${WHITE}$DB_PASSWORD${NC}"
}

showdelimiter(){
        echo
        echo '-------------------'
        echo
}

title(){
    echo -e "${D_VIOL}$1${NC}"
}

dumpStats(){
        echo
        echo -e "Current dir: ${WHITE}$(pwd)${NC}"
        # Config file
        if [[ ! -f $configFile ]]; then
                echo -e "${L_RED}Can't find config file!${NC}"
            else
                echo -e "App name: ${WHITE}$appName${NC}"
                echo -e "Config file: ${WHITE}$configFile${NC}"
        fi

        # DB dump
        if [ -f "$dbfile" ]; then
            dumpSize=$(du -k -h $dbfile | cut -f1 | tr -d ' ')
            dumpChangeDate=$(date -r $dbfile)
            echo -e "DB dump file: ${WHITE}$dbfile${NC}"
            echo -e "Remote or local dump: $(remoteOrLocalDump)"
            echo -e "Dump size: ${WHITE}$dumpSize${NC}"
            echo -e "Dump last changed: ${WHITE}$dumpChangeDate${NC}"
        else
        echo -e "${L_RED}No DB dump found!${NC}"
        fi
}

# Determines if dump made from local or remote DB
remoteOrLocalDump(){
    if [[ $remote -eq 1 ]]; then
#        Local
        echo -e "${WHITE}Local${NC}"
    elif [[ $remote -eq 2 ]]; then
#       Remote
        echo -e "${YELLOW}Remote (${remotePath})${NC}"
     else
        echo -e "Not sure ..."
    fi
}

surprise(){
    curl parrot.live
#    curl http://artscene.textfiles.com/asciiart/angela.art
#     curl http://artscene.textfiles.com/asciiart/cow.txt
}

PullDumpFromRemote(){
    echo
    echo -e "Remote host?"
#    Show previous host if it is not empty
    if [[ ! -z $host ]]; then
        oldhost=$host
        echo -e "Previous host: ${WHITE}${host}${NC}";
    fi
    read -p "For example, root@123.45.12.23 or enter for previous host: " host
    echo

    # if user just pushed enter and previous host is empty
    if [[ -z $host && -z $oldhost ]]; then
        echo -e "${L_RED}No host!${NC}"
        return
    # if user just pushed enter and previous host is NOT empty
    elif [[ -z $host && ! -z $oldhost ]]; then
        host=$oldhost
    fi

    echo -e "Path on remote?"
#    Show previous path if it is not empty
    if [[ ! -z $path ]]; then
        echo -e "Previous path: ${WHITE}${path}${NC}";
        oldpath=$path
    fi
    read -p "For example, /path/to/website or enter for previous path: " path
    echo

    # if user just pushed enter and previous path is empty
    if [[ -z $path && -z $oldpath ]]; then
        echo -e "${L_RED}No path!${NC}"
        return
    # if user just pushed enter and previous path is NOT empty
    elif [[ -z $path && ! -z $oldpath ]]; then
        path=$oldpath
    fi

    echo -e "Creating dump on remote server"
    echo
#    Triming trailing slash in path
    path=${path%%+(/)}
#    Creating dump on remote server and echoing only dump name
    remoteDump=`ssh -t $host "cd $path && $(declare -f getCredentials createDump check_command_exec_status); getCredentials; createDump > /dev/null 2>&1 ; printf "'$dbfile'`
    check_command_exec_status $?

#    In case $dbfile is not set
     if [ ! -f "$dbfile" ]; then
        dbfile=$remoteDump
    fi

#    Pulling dump from remote
    remotePath="${host}:${path}/${remoteDump}"
    echo -e "Pulling dump from remote ${remotePath}"
    scp "${remotePath}" "${dbfile}"
    check_command_exec_status $?

#    Removing dump from remote
    echo -e "Removing dump from remote ${remotePath}"
    ssh -t $host "cd $path && rm $remoteDump"
    check_command_exec_status $?

#    This is for dumpStats
    remote=2
}

selfUpdate(){
eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer bdsm
 check_command_exec_status $?
}

installOtherScripts(){
echo -e "What script do you want to install?
    ${WHITE}1.${NC} Go Git Aliases — ${YELLOW}https://github.com/michaelradionov/git-alias${NC}
    ${WHITE}2.${NC} HelloBash — ${YELLOW}https://github.com/michaelradionov/helloBash${NC}
    ${WHITE}3.${NC} Install Micro Editor — ${YELLOW}https://gist.github.com/michaelradionov/156daa2058d004f8bfe9356f7f2bf5de${NC}"
    read -p "Type number: " script
    case $script in
    1)
        title "Installing Go Git Aliases"
        echo -e "Check it out at https://github.com/michaelradionov/git-alias"
        eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer gg_aliases
       ;;
   2)
      title "Installing Hello Bash"
      echo -e "Check it out at https://github.com/michaelradionov/helloBash"
      eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer hello_bash
      ;;
    3)
       title "Installing Micro Editor"
       echo -e "Check it out at https://gist.github.com/michaelradionov/156daa2058d004f8bfe9356f7f2bf5de"
       cd ; curl https://getmic.ro | bash; echo 'alias m="~/micro"' >> .bashrc; source ~/.bashrc;
       ;;
    esac
}

askUserNoVariants(){
read -p "What do you want from me? (1-9, 'q' or enter for help): " action
}

askUserWithVariants(){
echo -e "What do you want from me?
    ${WHITE}1.${NC} Show Credentials
    ${WHITE}2.${NC} Export DB locally
    ${WHITE}3.${NC} Search in dump
    ${WHITE}4.${NC} Search/Replace in dump
    ${WHITE}5.${NC} Import dump
    ${WHITE}6.${NC} Pull DB from remote server
    ${WHITE}7.${NC} Delete Dump
    ${WHITE}8.${NC} Self-update
    ${WHITE}9.${NC} Install other scripts ${L_RED}HOT!${NC}

    ${WHITE}10.${NC} Look for dump elsewhere locally ${YELLOW}NEW!${NC}
    ${WHITE}11.${NC} Enter credentials manually ${YELLOW}NEW!${NC}
    ${WHITE}12.${NC} Forget credentials and dumpfile ${YELLOW}NEW!${NC}

    ${WHITE}p.${NC} Party! Ctrl+C to exit party
    ${WHITE}q.${NC} Exit"
read -p "Type number (1-9 or 'q' for exit): " action
}

###################################################
# Routing
###################################################
doStuff(){
    case $action in
    1)
        title 'showCredentials'
        getCredentials
        showCredentials
        ;;
    2)
        title 'createDump'
        createDump
       ;;
    3)
        title 'SearchInDump'
        SearchInDump
        ;;
    4)
        title 'searchReplaceInDump'
        searchReplaceInDump
        ;;
    5)
        title 'importDump'
        importDump
        ;;
    6)
        title 'PullDumpFromRemote'
        PullDumpFromRemote
        ;;
    7)
        title 'deleteDump'
        deleteDump
        ;;
    8)
        title 'selfUpdate'
        echo
        selfUpdate
        ;;
    9)
        title 'installOtherScripts'
        echo
        installOtherScripts
        ;;
    10)
      title 'FindDump'
      echo
      FindDump
    ;;
    11)
      title 'EnterCredentials'
      echo
      EnterCredentials
    ;;
    12)
      title 'ForgetEverything'
      echo
      ForgetEverything
    ;;
    'p')
        surprise
        ;;
    'q')
        title 'Bye!'
        return 1
        ;;
    *)
#        default
        title 'Need help?'
        getCredentials
        dumpStats
        showdelimiter
        askUserWithVariants
        showdelimiter
        doStuff
        ;;
    esac
}

###########################

bdsm(){

getCredentials
showdelimiter
title "Hello from ${YELLOW}${SCRIPT_NAME}${D_VIOL} script!"

while :
    do
        showdelimiter
        askUserNoVariants
        showdelimiter
        doStuff || break
    done
return


}
