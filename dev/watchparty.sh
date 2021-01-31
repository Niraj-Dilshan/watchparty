# Allow ssh, http, https
ufw allow http
ufw allow https
ufw allow ssh
# Enable ufw
ufw enable

# Install nginx/bind9
apt install -y nginx
apt install -y bind9

echo 'events {}
http {
  upstream roundrobin {
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
    server 127.0.0.1:3003;
  }

  upstream 1 {
    server 127.0.0.1:3001;
  }

  upstream 2 {
    server 127.0.0.1:3002;
  }

  upstream 3 {
    server 127.0.0.1:3003;
  }

  map $http_x_server_select $pool {
     default "roundrobin";
     1 "1";
     2 "2";
     3 "3";
  }

  server {
    listen 3000;
    location / {
      proxy_pass http://$pool;
    }
  }
}' > /etc/nginx/nginx.conf
/etc/init.d/nginx reload

# Install git
apt update
apt install -y git

# Clone application code
git clone https://github.com/howardchung/watchparty

# Install docker
curl -sSL https://get.docker.com/ | sh
# Start Redis
sudo docker run --log-opt max-size=1g -d --name redis --restart=always --net=host redis
# Start Postgres
sudo docker run --log-opt max-size=1g -d --name postgres --restart=always -e POSTGRES_PASSWORD=password --net=host -v $PWD/sql/:/docker-entrypoint-initdb.d/ postgres

# Install NodeJS
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# Set up certbot or Cloudflare HTTPS

# Build watchparty
npm run build

# Set .env config
echo '
DATABASE_URL=postgresql://postgres@localhost:5432/postgres?sslmode=disable
REDIS_URL=localhost:6379
' > .env

# Install PM2 globally
npm install -g pm2

# PM2 start
npm run pm2

# Run on startup
./node_modules/pm2/bin/pm2 startup
./node_modules/pm2/bin/pm2 save