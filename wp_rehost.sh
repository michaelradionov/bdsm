#!/bin/bash

check_command_exec_status () {
  if [ $1 -eq 0 ]
    then
      echo -e "${YELLOW}Выполнено успешно!${NC}"
      echo
      sleep 1
  else
    echo -e "${L_RED}ERROR${NC}"
    echo

  fi
}

wprehost(){
  #!/bin/bash
  set -e
  # Ищем wp-config.php

  if [ -f wp-config.php ]; then
      echo "Нашел wp-config.php в текущей директории!"
      CONF=wp-config.php
  else
    if [ -f ../wp-config.php ]; then
      echo "Нашел wp-config.php уровнем выше!"
      CONF=../wp-config.php
    else
      echo "Не нашел wp-config.php в текущей и родительской директориях"
      return
    fi

  fi

  # cat $CONF

  # Получаем данные для подключения к БД

    WPDBNAME=`cat "$CONF" | grep DB_NAME | cut -d \' -f 4`
    WPDBUSER=`cat "$CONF" | grep DB_USER | cut -d \' -f 4`
    WPDBPASS=`cat "$CONF" | grep DB_PASSWORD | cut -d \' -f 4`


    echo
    echo "Имя базы: $WPDBNAME"
    echo "Имя юзера: $WPDBUSER"
    echo "Пароль: $WPDBPASS"
    echo

read -p 'Экспортировать БД? (y/n): ' x
case $x in
y)

  echo
  echo "Делаю дамп БД";
  mysqldump -u$WPDBUSER -p$WPDBPASS $WPDBNAME > ./db_$WPDBNAME.sql
  dbfile="db_$WPDBNAME.sql"
  check_command_exec_status $?

  read -p 'Произвести поиск по дампу БД? (y/n): ' y
    case $y in
      y)
        echo
        echo
        read -p 'Строка поиска: ' old_domain
        echo
        echo "Выполняю поиск";

        find=`grep -o "$old_domain" "$dbfile" | wc -l | tr -d " "`;
        check_command_exec_status $?

        echo "Найдено $find вхождений $old_domain";

        echo
        read -p 'Произвести замену строки '$old_domain' в дампе БД? (y/n): ' yy
        case $yy in
          y)
          echo
          echo
          read -p 'Строка замены: ' new_domain
          echo
          echo "Делаем искалово-заменялово";

           # sed 's/'$old_domain'/'$new_domain'/g' "$dbfile"
           perl -pi -w -e 's|'$old_domain'|'$new_domain'|g;' "$dbfile"
           check_command_exec_status $?

            read -p "Заливаем? (y/n): " yyy
            case $yyy in
              y)
             echo "Делаем заливалово";
             mysql -u$WPDBUSER -p$WPDBPASS $WPDBNAME < ./$dbfile
             check_command_exec_status $?

             echo "Удалялово";
             rm -f $dbfile
             check_command_exec_status $?
             ;;
             *)
             echo "Отбой";
           ;;
          esac # Заливаем? (y/n)
          ;;
          *)
            echo "Отбой";
          ;;
        esac # Произвести замену строки '$old_domain' в дампе БД?
        ;;
      *)
        echo 'Отбой';
        ;;
  esac # Произвести поиск по дампу БД? (y/n)
;;
*)
read -p "Импортировать БД? (y/n): " xy
case $xy in
  y)
    read -p "Имя дампа (файл БД для импорта): " name
      echo "Делаем заливалово";
      if [[ $name = '' ]]; then
        dbfile="db_$WPDBNAME.sql"
      else
        dbfile=$name;
      fi
      # echo $dbfile;
      mysql -u$WPDBUSER -p$WPDBPASS $WPDBNAME < ./$dbfile
      check_command_exec_status $?
  ;;
  *)
  echo 'Отбой';
  ;;
esac
;;
esac # Экспортировать БД? (y/n)
} # wprehost()
