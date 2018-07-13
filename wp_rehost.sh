#!/bin/bash

# Colors
L_RED='\033[1;31m'
L_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
D_GREY='\033[1;30m'
D_VIOL='\033[1;34m'
NC='\033[0m'

check_command_exec_status () {
  if [ $1 -eq 0 ]
    then
      echo -e "${YELLOW}Success!${NC}"
      echo
  else
    echo -e "${L_RED}ERROR${NC}"
    echo
  fi
}

wprehost(){

  # Looking for wp-config.php (WordPress) or .env (Laravel)

  if [ -f wp-config.php ]; then
      echo "Found wp-config.php in current directory!"

      # Retriving credentials for DB connection
      CONF=wp-config.php
      DB_DATABASE=`cat "$CONF" | grep DB_NAME | cut -d \' -f 4`
      DB_USERNAME=`cat "$CONF" | grep DB_USER | cut -d \' -f 4`
      DB_PASSWORD=`cat "$CONF" | grep DB_PASSWORD | cut -d \' -f 4`

  elif [[ -f .env ]]; then
      echo "Found .env in current directory!"
      source .env
  else
    echo -e "${L_RED}Can't find neither wp-config.php nor .env in current directory... :(${NC}"
    return
  fi


    echo
    echo -e "DB name: ${L_GREEN}$DB_DATABASE${NC}"
    echo -e "DB user: ${L_GREEN}$DB_USERNAME${NC}"
    echo -e "DB password: ${L_GREEN}$DB_PASSWORD${NC}"
    echo

read -p 'Export DB? (y/n): ' x
case $x in
y)

  echo
  echo "Making DB dump...";
  mysqldump -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > ./$DB_DATABASE.sql
  dbfile="$DB_DATABASE.sql"
  check_command_exec_status $?

  read -p 'Search in DB dump? (y/n): ' y
    case $y in
      y)
        echo
        echo
        read -p 'Search string: ' old_domain
        echo
        echo "Searching...";

        find=`grep -o "$old_domain" "$dbfile" | wc -l | tr -d " "`;
        check_command_exec_status $?

        echo "Found $find occurrences of $old_domain";

        echo
        read -p "Replace ${old_domain} in DB dump? (y/n): " yy
        case $yy in
          y)
          echo
          echo
          read -p 'Replace string: ' new_domain
          echo
          echo "Replacing...";

           perl -pi -w -e "s|${old_domain}|${new_domain}|g;" "$dbfile"
           check_command_exec_status $?

            read -p "Import? (y/n): " yyy
            case $yyy in
              y)
             echo "Importing...";
             mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < ./$dbfile
             check_command_exec_status $?

             echo "Deleting dump...";
             rm -f $dbfile
             check_command_exec_status $?
             ;;
             *)
             echo "Abort";
           ;;
         esac # Import
          ;;
          *)
            echo "Abort";
          ;;
        esac # Replace
        ;;
      *)
        echo 'Abort';
        ;;
  esac # Search
;;
*)
read -p "Import DB? (y/n): " xy
case $xy in
  y)
    read -p "Dump file name (empty for default name): " name
      echo "Importing...";
      if [[ $name = '' ]]; then
        dbfile="$DB_DATABASE.sql"
      else
        dbfile=$name;
      fi
      # echo $dbfile;
      mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < ./$dbfile
      check_command_exec_status $?
  ;;
  *)
  echo 'Abort';
  ;;
esac
;;
esac # Export DB? (y/n)
} # wprehost()
