#!/bin/bash

SCRIPT_NAME="WP_REHOST"

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

# Deletes dump
deleteDump(){
  echo "Deleting dump...";
  rm -f $dbfile
  check_command_exec_status $?
}

# Imports dump
importDump(){
  echo "Importing...";
  mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < ./$dbfile
  check_command_exec_status $?
}

# Searches in DB dump
SearchInDump(){
    echo
    if [ ! -f "$dbfile" ]; then
        echo -e "${L_RED}No ${dbfile} found!${NC}"
        return
    fi
    read -p 'Search string: ' old_domain
    echo
    echo "Searching...";
    find=`grep -o "$old_domain" "$dbfile" | wc -l | tr -d " "`;
    check_command_exec_status $?
    echo -e "Found ${WHITE}$find${NC} occurrences of $old_domain";
    echo
}

# Search and replace in dump
searchReplaceInDump(){
  SearchInDump
  echo
  if [ ! -f "$dbfile" ]; then
    echo -e "${L_RED}No ${dbfile} found!${NC}"
    return
fi
  read -p 'Replace string: ' new_domain
  echo
  echo "Replacing...";

   perl -pi -w -e "s|${old_domain}|${new_domain}|g;" "$dbfile"
   check_command_exec_status $?
}

# get DB credentials from config file
getCredentials(){
  # Looking for config file

# WordPress
  if [ -f wp-config.php ]; then
       configFile=wp-config.php
      # Retrieving credentials for DB connection
      CONF=wp-config.php
      DB_DATABASE=`cat "$CONF" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$CONF" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$CONF" | grep DB_PASSWORD | cut -d \' -f 4`

# Laravel
  elif [[ -f .env ]]; then
      configFile=.env
      source .env
  else
    DB_DATABASE=''
    DB_USERNAME=''
    DB_PASSWORD=''
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
  mysqldump -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > ./$DB_DATABASE.sql
  dbfile="$DB_DATABASE.sql"
  check_command_exec_status $?
#    This is for dumpStats
  remote=1
}

CheckAndSearchInDump(){
     if [ -f "$dbfile" ]; then
        SearchInDump
        else
            echo -e "${L_RED}No ${dbfile} found!${NC}"
        return
    fi
}

showCredentials(){
  echo
  echo -e "DB name: ${WHITE}$DB_DATABASE${NC}"
  echo -e "DB user: ${WHITE}$DB_USERNAME${NC}"
  echo -e "DB password: ${WHITE}$DB_PASSWORD${NC}"
}

askUserNoVariants(){
read -p "What do you want from me? (1-9, enter for help): " action
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
        # Config file
        if [[ -z $DB_DATABASE ]]; then
                echo -e "${L_RED}Can't find neither wp-config.php nor .env in current directory${NC}"
            else
                echo -e "Config file: ${WHITE}$configFile${NC}"
        fi

        # DB dump
        if [ -f "$dbfile" ]; then
            dumpSize=$(du -k -h $dbfile | cut -f1 | tr -d ' ')
            dumpChangeDate=$(date -r $dbfile)
            echo -e "DB dump file: ${WHITE}$dbfile${NC}"
            echo -e "Remote or local dump: $(remoteOrLocalDump)"
            echo -e "Size: ${WHITE}$dumpSize${NC}"
            echo -e "Last changed: ${WHITE}$dumpChangeDate${NC}"
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
    read -p "Remote host? For example, root@123.45.12.23 or 47: " host
    echo
    read -p "Path on remote? For example, /path/to/website: " path
    echo -e "Creating dump on remote server"
    echo
#    Triming trailing slash
    path=${path%%+(/)}
#    Creating dump on remote server and echoing only dump name
    remoteDump=`ssh -t $host "cd $path && $(declare -f getCredentials createDump dumpStats check_command_exec_status); getCredentials; createDump > /dev/null 2>&1 ; dumpStats > /dev/null 2>&1;printf "'$dbfile'`
    check_command_exec_status

#    In case $dbfile is not set
     if [ ! -f "$dbfile" ]; then
        dbfile=$remoteDump
    fi

#    Pulling dump from remote
    remotePath="${host}:${path}/${remoteDump}"
    echo -e "Pulling dump from remote ${remotePath}"
    scp "${remotePath}" "${dbfile}"
    check_command_exec_status
#    This is for dumpStats
    remote=2
}


askUserWithVariants(){
echo -e "What do you want from me?
    ${WHITE}1.${NC} Show Credentials
    ${WHITE}2.${NC} Export DB locally
    ${WHITE}3.${NC} Search in dump
    ${WHITE}4.${NC} Search/Replace in dump
    ${WHITE}5.${NC} Import dump
    ${WHITE}6.${NC} Export dump and pull from remote website
    ${WHITE}7.${NC} Party! Ctrl+C to exit party
    ${WHITE}9.${NC} Exit"
read -p "Type number (1-9): " action
}

###################################################
# Routing
###################################################
doStuff(){
    case $action in
    1)
        title 'showCredentials'
        showCredentials
        ;;
    2)
        title 'createDump'
        createDump
       ;;
    3)
        title 'CheckAndSearchInDump'
        CheckAndSearchInDump
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
        title "Surprise!"
        surprise
        ;;
    9)
        title 'Bye!'
        break
        ;;
    *)
#        default
        title 'Need help?'
        dumpStats
        showdelimiter
        askUserWithVariants
        showdelimiter
        doStuff
        ;;
    esac
}

###########################

wprehost(){

getCredentials

showdelimiter
title "Hello from $SCRIPT_NAME script!"

while :
    do
        showdelimiter
        askUserNoVariants
        showdelimiter
        doStuff
    done
return


} # wprehost()
