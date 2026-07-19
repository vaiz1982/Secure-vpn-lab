cd /var/www/html
git pull origin main
npm install
pm2 restart all
sudo systemctl status nginx
cat /etc/hosts
ssh deploy@staging-internal
scp app.env deploy@staging-internal:/opt/app/.env
cd ~
history
