mysqldump -u root -p252525 obl_2 > ./db.sql
echo "dump created";
sed -i "" 's/obl.flagstudio.ru/obl.loc/g' db.sql
echo "domain replaced";
mysql -u root -p252525 obl_2 < ./db.sql
echo "dump uploaded";
rm -f db.sql
echo "dump deleted";
