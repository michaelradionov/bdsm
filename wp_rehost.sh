read -p 'название базы?:' db
read -p 'название юзера?:' user
read -p 'пароль?:' pass
read -p 'какой домен сейчас?:' old_domain
read -p 'какой домен надо?:' new_domain

mysqldump -u$user -p$pass $db > ./db.sql
echo "dump created";
sed -i "" 's/'$old_domain'/'$new_domain'/g' db.sql
echo "domain replaced";
mysql -u root -p252525 obl_2 < ./db.sql
echo "dump uploaded";
rm -f db.sql
echo "dump deleted";
