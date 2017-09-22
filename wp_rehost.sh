#!/bin/bash
set -e
echo
echo
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
    exit
  fi

fi

cat $CONF

# Получаем данные для подключения к БД


  WPDBNAME=`cat "$CONF" | grep DB_NAME | cut -d \' -f 4`
  WPDBUSER=`cat "$CONF" | grep DB_USER | cut -d \' -f 4`
  WPDBPASS=`cat "$CONF" | grep DB_PASSWORD | cut -d \' -f 4`

  echo
  echo

  echo "Имя базы: $WPDBNAME"
  echo "Имя юзера: $WPDBUSER"
  echo "Пароль: $WPDBPASS"

echo
echo


read -p 'какой домен сейчас?:' old_domain
read -p 'какой домен надо?:' new_domain

mysqldump -u$WPDBUSER -p$WPDBPASS $WPDBNAME > ./db.sql
echo "dump created";
sed -i "" 's/'$old_domain'/'$new_domain'/g' db.sql
echo "domain replaced";
mysql -u$WPDBUSER -p$WPDBPASS $WPDBNAME < ./db.sql
echo "dump uploaded";
rm -f db.sql
echo "dump deleted";
