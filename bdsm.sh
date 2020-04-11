#!/bin/bash

# BDSM – Bash Database SQL Manager
# https://github.com/michaelradionov/bdsm



getBackupsFolderName(){
  echo "db_backups"
}

generateDumpName(){
  dump_name="${DB_DATABASE}_${DB_CONNECTION}_$(date +%Y-%m-%d__%H-%M).sql"
  echo $dump_name
}

# Variables
  SCRIPT_NAME="bdsm"
  BACKUP_FOLDER=$(getBackupsFolderName)
  SCRIPTS_FOLDER=~/.gg_tools

# Colors
  L_RED='\033[1;31m'
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
# If dump doesn't exists
    if [ ! -f "$BACKUP_FOLDER/$dbfile" ]; then
        echo -e "${L_RED}No DB dump file found!${NC}"
        return 1
    fi
}

# Deletes dump
deleteDump(){
   echo
  isDumpExists || return
  echo "Deleting dump...";
  rm -f "$BACKUP_FOLDER/$dbfile"
  check_command_exec_status $?
}

# Imports dump
importDump(){
  isDumpExists || return
    if [[ -z $container ]]; then
    # Not in Docker mode
      echo "Importing locally";
#      MySQL
    if [[ $DB_CONNECTION == "mysql" ]]; then
      mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE --force < "$BACKUP_FOLDER/$dbfile"
    fi
#    PostgreSQL
    if [[ $DB_CONNECTION == "pgsql" ]]; then
      echo "Droping DB...";
      PGPASSWORD=$DB_PASSWORD dropdb -U $DB_USERNAME $DB_DATABASE

      if [[ $? -eq 0 ]]; then
      echo "Creating DB...";
      PGPASSWORD=$DB_PASSWORD createdb -U $DB_USERNAME $DB_DATABASE
        if [[ $? -eq 0 ]]; then
          echo "Importing dump...";
          PGPASSWORD=$DB_PASSWORD psql --quiet -U $DB_USERNAME  $DB_DATABASE < "$BACKUP_FOLDER/$dbfile"
          check_command_exec_status $?
        fi
      else
          check_command_exec_status 1
      fi

    fi
  else
    # Docker mode
    echo "Importing in Docker Container";
#    MySQL
    if [[ $DB_CONNECTION == "mysql" ]]; then
      cat "$BACKUP_FOLDER/$dbfile" | docker exec -i $container /usr/bin/mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE
    fi
#    PostgreSQL
    if [[ $DB_CONNECTION == "pgsql" ]]; then

      echo "Droping DB...";
      docker exec -i $container /usr/local/bin/dropdb -U $DB_USERNAME $DB_DATABASE

      if [[ $? -eq 0 ]]; then

        echo "Creating DB...";
        docker exec -i $container /usr/local/bin/createdb -U $DB_USERNAME $DB_DATABASE

        if [[ $? -eq 0 ]]; then

          echo "Importing dump...";
          cat "$BACKUP_FOLDER/$dbfile" | docker exec -i $container /usr/local/bin/psql --quiet -U $DB_USERNAME -d $DB_DATABASE
          check_command_exec_status $?
        fi
      else
        check_command_exec_status 1
      fi
    fi
  fi
}


# Enter credentials manually
EnterCredentials(){
#      read -p "Enter Mysql host: " DB_HOST
      read -p "Enter DB name: " DB_DATABASE
      read -p "Enter DB user: " DB_USERNAME
      read -p "Enter DB password: " DB_PASSWORD
      read -p "Enter DB connection (mysql or pgsql): " DB_CONNECTION
}


# Searches in DB dump
SearchInDump(){
    echo
    isDumpExists || return
    read -p 'Search string: ' old_domain
    echo
    echo -e "Searching for ${WHITE}${old_domain}${NC} in ${WHITE}${dbfile}${NC}";
    find=`grep -o "$old_domain" "$BACKUP_FOLDER/$dbfile" | wc -l | tr -d " "`;
    check_command_exec_status $?
    echo -e "Found ${WHITE}$find${NC} occurrences of $old_domain";
    echo
}

# Search and replace in dump
searchReplaceInDump(){
  SearchInDump
  echo
  isDumpExists || return
  read -p 'Replace string (q to exit): ' new_domain
  if [[ $new_domain == "q" ]] || [[ -z $new_domain ]]; then
      echo -e "${L_RED}Not doing search/replace!${NC}"
      return 0
  fi
  echo
  echo -e "Replacing ${WHITE}${old_domain}${NC} with ${WHITE}${new_domain}${NC} in ${WHITE}${dbfile}${NC}";

   perl -pi -w -e "s|${old_domain}|${new_domain}|g;" "$BACKUP_FOLDER/$dbfile"
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
#      DB_HOST=`cat "$configFile" | grep DB_HOST | cut -d \' -f 4`
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWORD | cut -d \' -f 4`
      DB_CONNECTION='mysql'

# WordPress from wp-content. Long story. We have some oldest repos in wp-content folder
  elif [ -f ../wp-config.php ]; then
      appName='WordPress'
      configFile=../wp-config.php
#      DB_HOST=`cat "$configFile" | grep DB_HOST | cut -d \' -f 4`
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWORD | cut -d \' -f 4`
      DB_CONNECTION='mysql'

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
      DB_CONNECTION='mysql'

# Prestashop 1.6
  elif [[ -f config/settings.inc.php ]]; then
      appName='Prestashop 1.6'
      configFile=config/settings.inc.php
      DB_DATABASE=`cat "$configFile" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$configFile" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$configFile" | grep DB_PASSWD | cut -d \' -f 4`
      DB_CONNECTION='mysql'

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
  if [[ -z $DB_DATABASE ]] || [[ -z $DB_USERNAME ]]; then
     echo -e "${L_RED}Sorry, credentials is not set :(${NC}"
     return
  fi
  if [ -z $BACKUP_FOLDER ]; then
      BACKUP_FOLDER=$(getBackupsFolderName)
  fi
  checkAndCreateBackupFolder
  if [[ -z $container ]]; then
    # Not in Docker mode
    echo -e "Making DB dump locally in ${WHITE}${BACKUP_FOLDER}/$(generateDumpName)${NC}";

#    MySQL connection
    if [[ $DB_CONNECTION == "mysql" ]]; then
      mysqldump --single-transaction -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > "${BACKUP_FOLDER}/$(generateDumpName)"
    fi

#    PostgreSQL connection
    if [[ $DB_CONNECTION == "pgsql" ]]; then
        PGPASSWORD=$DB_PASSWORD pg_dump -U $DB_USERNAME  $DB_DATABASE > "${BACKUP_FOLDER}/$(generateDumpName)"
    fi

    check_command_exec_status $?
    #    This is for dumpStats
      remote=1
  else
    # Docker mode
    echo "Making DB dump from Docker container";
    if [[ $DB_CONNECTION == "mysql" ]]; then
      docker exec $container /usr/bin/mysqldump --single-transaction -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > "${BACKUP_FOLDER}/$(generateDumpName)"
    fi
    if [[ $DB_CONNECTION == "pgsql" ]]; then
      docker exec $container /usr/local/bin/pg_dump -U $DB_USERNAME $DB_DATABASE > "${BACKUP_FOLDER}/$(generateDumpName)"
    fi

    check_command_exec_status $?
    #    This is for dumpStats
    remote=3
  fi
  dbfile=$(generateDumpName)
}

showCredentials(){
  echo
#  echo -e "DB host: ${WHITE}$DB_HOST${NC}"
  echo -e "DB connection: ${WHITE}$DB_CONNECTION${NC}"
  echo -e "DB name: ${WHITE}$DB_DATABASE${NC}"
  echo -e "DB user: ${WHITE}$DB_USERNAME${NC}"
  echo -e "DB password: ${WHITE}$DB_PASSWORD${NC}"
  echo
#  dumpStats
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
        if [ -f "$BACKUP_FOLDER/$dbfile" ]; then
            dumpSize=$(du -k -h "$BACKUP_FOLDER/$dbfile" | cut -f1 | tr -d ' ')
            dumpChangeDate=$(date -r "$BACKUP_FOLDER/$dbfile")
            echo -e "DB dump file: ${WHITE}$dbfile${NC}"
            echo -e "DB type: ${WHITE}$DB_CONNECTION${NC}"
            echo -e "Remote or local dump: $(remoteOrLocalDump)"
            echo -e "Dump size: ${WHITE}$dumpSize${NC}"
            echo -e "Dump last changed: ${WHITE}$dumpChangeDate${NC}"
        else
        echo -e "${L_RED}No DB dump found!${NC}"
        fi
        # Docker container
          if [[ ! -z $container ]]; then
            echo -e "Docker container: ${WHITE}$container${NC}"
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
    elif [[ $remote -eq 3 ]]; then
#       Remote
        echo -e "${D_GREY}Local from Docker container${NC}"
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
    read -p "For example, root@123.45.12.23 or just hit 'enter' for previous host: " host
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
    remoteDump=$(ssh -t $host "cd $path && $(declare -f getCredentials createDump check_command_exec_status getFirstContainer generateDumpName checkAndCreateBackupFolder getBackupsFolderName); getCredentials; getFirstContainer  > /dev/null 2>&1 ; createDump > /dev/null 2>&1 ; printf "'$dbfile')
    check_command_exec_status $?

#    Pulling dump from remote
    remotePath="${host}:${path}/${BACKUP_FOLDER}/${remoteDump}"
    dbfile=$remoteDump
    echo -e "Pulling dump from remote ${remotePath}"
    scp "${remotePath}" "${BACKUP_FOLDER}/${dbfile}"
    check_command_exec_status $?

#    Removing dump from remote
    echo -e "Removing dump from remote ${remotePath}"
    ssh -t $host "cd $path/$BACKUP_FOLDER && rm $remoteDump"
    check_command_exec_status $?

#    This is for dumpStats
    remote=2
}

getFirstContainer(){
  if [[ $DB_CONNECTION == "mysql" ]]; then
    container=$(docker ps --format {{.Names}} | grep mysql)
  fi
  if [[ $DB_CONNECTION == "pgsql" ]]; then
    container=$(docker ps --format {{.Names}} | grep postgres)
  fi
}

selfUpdate(){
eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer bdsm
 check_command_exec_status $?
}

installOtherScripts(){
echo -e "What script do you want to install?
    ${WHITE}1.${NC} Go Git Aliases — ${YELLOW}https://github.com/michaelradionov/aliases${NC}
    ${WHITE}2.${NC} HelloBash — ${YELLOW}https://github.com/michaelradionov/helloBash${NC}
    ${WHITE}3.${NC} Install Micro Editor (Mac & Linux) — ${YELLOW}https://gist.github.com/michaelradionov/156daa2058d004f8bfe9356f7f2bf5de${NC}
    ${WHITE}4.${NC} Install Docker Aliases — ${YELLOW}https://github.com/michaelradionov/aliases${NC}
    ${WHITE}5.${NC} Install Laravel Aliases — ${YELLOW}https://github.com/michaelradionov/aliases${NC}
    ${WHITE}6.${NC} Install Jira Aliases — ${YELLOW}https://github.com/michaelradionov/aliases${NC}
    ${WHITE}7.${NC} Install Random Aliases — ${YELLOW}https://github.com/michaelradionov/aliases${NC}
    ${WHITE}8.${NC} Install Docker on Ubuntu 16.04 — ${YELLOW}https://gist.github.com/michaelradionov/84879dc686e7f9e43bc38ecbbd879af4${NC}
    ${WHITE}9.${NC} Install Brancher script for switching branches — ${YELLOW}https://github.com/Flagstudio/brancher${NC}"
    read -p "Type number: " script
    case $script in
    1)
        InstallGoGitAliases
       ;;
   2)
        InstallHelloBash
      ;;
    3)
        InstallMicroEditor
       ;;
   4)
        InstallDockerAliases
      ;;
    5)
        InstallLaravelAliases
       ;;
   6)
        InstallJiraAliases
      ;;
  7)
        InstallRandomAliases
     ;;
  8)
        InstallDockerOnUbuntu16
     ;;
  9)
        InstallBrancher
     ;;
    esac
}

InstallGoGitAliases(){
        title "Installing Go Git Aliases"
        echo -e "Check it out at https://github.com/michaelradionov/git-alias"
        eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer gg_aliases
}
InstallHelloBash(){
      title "Installing Hello Bash"
      echo -e "Check it out at https://github.com/michaelradionov/helloBash"
      eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer hello_bash
}
InstallMicroEditor(){
       title "Installing Micro Editor"
       echo -e "Check it out at https://gist.github.com/michaelradionov/156daa2058d004f8bfe9356f7f2bf5de"
       cd ; curl https://getmic.ro | bash; echo 'alias m="~/micro"' >> .bashrc; source ~/.bashrc;
}
InstallDockerAliases(){
      title "Installing Docker Aliases"
      echo -e "Check it out at https://github.com/michaelradionov/aliases"
      eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer docker_aliases
}
InstallLaravelAliases(){
       title "Installing Laravel Aliases"
       echo -e "Check it out at https://github.com/michaelradionov/aliases"
       eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer laravel_aliases
}
InstallJiraAliases(){
      title "Installing Jira Aliases"
      echo -e "Check it out at https://github.com/michaelradionov/aliases"
      eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer jira_aliases

}
InstallRandomAliases(){
     title "Installing Random Aliases"
     echo -e "Check it out at https://github.com/michaelradionov/aliases"
     eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer random_aliases

}
InstallDockerOnUbuntu16(){
       title "Installing Docker on Ubuntu 16.04"
       echo -e "Check it out at https://gist.github.com/michaelradionov/84879dc686e7f9e43bc38ecbbd879af4"
       curl https://gist.githubusercontent.com/michaelradionov/84879dc686e7f9e43bc38ecbbd879af4/raw/17f942d078b5b2202dd12eab9a5c4d55b4a06259/Docker_Ubuntu_16.sh | sudo bash
}
InstallBrancher(){
       title "Installing Brancher"
       echo -e "Check it out at https://github.com/Flagstudio/brancher"
      eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer brancher
}


ChooseDockerContainer(){
    read -p "Enter container name, type 'forget' to forget OR leave empty to let BDSM find one: " container
    if [[ -z $container ]]; then
        getFirstContainer
    elif [[ $container == 'forget' ]]; then
        unset container
    fi
}

chooseDump(){


  if [ -z "$(ls -A "$BACKUP_FOLDER")" ]; then
    echo -e "${L_RED}${BACKUP_FOLDER} is empty!${NC}"
    return
  fi

  files=( "${BACKUP_FOLDER}"/* )

  echo "The following DB dump files were found; select one: "
  echo
  COLUMNS=12
  PS3="Use number to select a file or 'q' to cancel: "
  select filename in "${files[@]}"
  do
      if [[ "$REPLY" == q ]]; then break; fi
      if [[ "$filename" == "" ]]
      then
          echo "'$REPLY' is not a valid number"
          continue
      fi
      dbfile=$(basename "$filename")
      check_command_exec_status $?
      echo
      echo -e "${WHITE}$dbfile${NC} choosed"
      break
  done
}

checkAndCreateBackupFolder(){

  if [ -n "$1" ]; then BACKUP_FOLDER=$1; fi

  if [ ! -d "$BACKUP_FOLDER" ]; then
      echo -e "Making ${WHITE}${BACKUP_FOLDER}${NC} directory for database backups..."
      mkdir -p "$BACKUP_FOLDER"
      check_command_exec_status $?
  fi
}

count_dumps_and_remove_old_dumps_by_count(){
    BACKUPS_COUNT_LIMIT=$1
    BACKUPS_COUNT=$(ls -1q "$BACKUP_FOLDER" | wc -l)
    echo -e "There is $BACKUPS_COUNT files in $BACKUP_FOLDER"

    if [ "$BACKUPS_COUNT" -gt "$BACKUPS_COUNT_LIMIT" ]; then
      echo -e "You have ${WHITE}$BACKUPS_COUNT${NC} backups and backup limit is ${WHITE}$BACKUPS_COUNT_LIMIT${NC}"
      echo -e "${L_RED}Removing extras...${NC}"
      ls -tp "$BACKUP_FOLDER" | grep -v '/$' | tail -n +$((BACKUPS_COUNT_LIMIT + 1)) | awk "{print \"$BACKUP_FOLDER/\"\$1}" | xargs -I {} rm {}
    fi
}



askUserNoVariants(){
    read -p "What do you want from me? (type number of action, 'q' or enter for help): " action
}

askUserWithVariants(){
echo -e "What do you want from me?
    ${WHITE}1.${NC} Show Credentials
    ${WHITE}2.${NC} Export DB locally
    ${WHITE}3.${NC} Search in dump
    ${WHITE}4.${NC} Search/Replace in dump
    ${WHITE}5.${NC} Import dump
    ${WHITE}6.${NC} Pull DB from remote server (with Docker support) ${L_RED}HOT!${NC}
    ${WHITE}7.${NC} Delete Dump
    ${WHITE}8.${NC} Self-update
    ${WHITE}9.${NC} Install other scripts ${L_RED}HOT!${NC}
    ${WHITE}10.${NC} Choose DB dump file from ${BACKUP_FOLDER} folder ${YELLOW}NEW!${NC}
    ${WHITE}11.${NC} Enter credentials manually
    ${WHITE}12.${NC} Choose/forget local Docker container

    ${WHITE}p.${NC} Party! Ctrl+C to exit the party
    ${WHITE}q.${NC} Exit"
read -p "Type number (type number of action or 'q' for exit): " action
}

###################################################
# Routing
###################################################
doStuff(){
    case $action in
    1)
        title 'showCredentials'
#        getCredentials
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
      title 'chooseDump'
      echo
      chooseDump
    ;;
    11)
      title 'EnterCredentials'
      echo
      EnterCredentials
    ;;
    12)
      title 'ChooseDockerContainer'
      echo
      ChooseDockerContainer
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
#        getCredentials
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

# First we'll check input flags
while [ -n "$1" ]
do
  case "$1" in

  "--install-all")

    showdelimiter
    title "Installing ALL the stuff..."
    InstallGoGitAliases
    InstallHelloBash
    InstallMicroEditor
    InstallDockerAliases
    InstallLaravelAliases
    InstallJiraAliases
    InstallRandomAliases

    return
    ;;

  "--nightly")

    showdelimiter
    title "Installing BDSM in nightly mode..."
    eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer bdsm_nightly
    check_command_exec_status $?

    echo -e "Removing ${SCRIPTS_FOLDER}/${SCRIPT_NAME}.sh ..."
    rm ${SCRIPTS_FOLDER}/${SCRIPT_NAME}.sh
    check_command_exec_status $?

    echo -e "To switch back to stable mode please install BDSM as usual with default command. More info https://github.com/michaelradionov/bdsm"

    return
    ;;

  "--backup")

    showdelimiter
    title "Automatic (Cron) mode"
    showdelimiter
    getCredentials
    getFirstContainer
    shift # Getting rid of "--backup" parameter

    while [ -n "$1" ]
    do
      case "$1" in
      -d)

        if [ -z "$2" ]; then
           echo -e "${L_RED}You must specify backups path when using the \"-d\" flag!${NC}"
           return
        fi

        if [ ! -d "$2" ]; then
           echo -e "${L_RED}$2 folder doesn't exist!${NC}"
           checkAndCreateBackupFolder "$2"
        fi

        echo -e "Changing backup folder path to ${WHITE}$2${NC}"
        BACKUP_FOLDER=$2
        check_command_exec_status $?

      shift # Getting rid of <path> parameter
      ;;

      -n)

        if [ -z "$2" ]; then
           echo -e "${L_RED}You must specify backups number using the \"-n\" flag!${NC}"
           return
        fi

        if ! [[ "$2" =~ ^[0-9]+$ ]]; then
           echo -e "${L_RED}$2 is not an integer!${NC}"
           return
        fi

        BACKUPS_COUNT_LIMIT=$2

      shift # Getting rid of <count> parameter
      ;;
      --zip)
        ZIP_BACKUP=true
      ;;

      *) echo "$1 is not a valid option. More info https://github.com/michaelradionov/bdsm";;
      esac
    shift # Getting rid of '-d' or '-n' or '--zip' parameters
    done

    createDump

#    Clean up backups because CLI flag input
    if ! [ -z "$BACKUPS_COUNT_LIMIT" ]; then
      count_dumps_and_remove_old_dumps_by_count "$BACKUPS_COUNT_LIMIT"
    fi

#    ZIP backup because CLI flag input
    if [ -n "$ZIP_BACKUP" ]; then
      tar --remove-files -czf "$BACKUP_FOLDER/$dbfile.tar.gz" "$BACKUP_FOLDER/$dbfile"
    fi

    return
    ;;

  *)

    echo -e "${L_RED}$1 is not an option${NC}"
    return
    ;;

  esac
shift
done

# If there is no inputs then we go interactive

getCredentials
getFirstContainer
checkAndCreateBackupFolder
showdelimiter
title "Hello from ${YELLOW}BDSM${D_VIOL} script!"

while :
    do
        showdelimiter
        askUserNoVariants
        showdelimiter
        doStuff || break
    done
return


}
