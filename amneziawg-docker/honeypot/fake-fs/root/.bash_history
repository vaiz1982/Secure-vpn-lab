ls -la
cd /var/www
cat /root/notes.txt
mysqldump -u root -p prod_db > /root/backup.sql
docker ps
vim /root/deploy_keys/backup_key
cd /opt
./update.sh
history -c
