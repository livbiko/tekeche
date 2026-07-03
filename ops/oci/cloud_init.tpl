#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# ── System packages ────────────────────────────────────────────────────────────
apt-get update -qq
apt-get install -y -qq curl gnupg nginx git openssl

# ── Node.js 20 ────────────────────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2

# ── MongoDB 8 ─────────────────────────────────────────────────────────────────
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
  | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-8.0.list
apt-get update -qq && apt-get install -y mongodb-org

cat > /etc/mongod.conf <<MONGOCFG
storage:
  dbPath: /var/lib/mongodb
net:
  port: 27017
  bindIp: 127.0.0.1,${standby_private_ip}
replication:
  replSetName: "${rs_name}"
security:
  authorization: enabled
MONGOCFG

systemctl enable mongod && systemctl start mongod

# ── Redis (replica of on-prem) ────────────────────────────────────────────────
apt-get install -y redis-server
sed -i 's/^bind .*/bind 127.0.0.1 ${standby_private_ip}/' /etc/redis/redis.conf
echo "replicaof ${onprem_nlb_vip} 6379" >> /etc/redis/redis.conf
echo "replica-read-only yes"            >> /etc/redis/redis.conf
systemctl enable redis-server && systemctl restart redis-server

# ── Clone tekeche-api ─────────────────────────────────────────────────────────
git clone ${github_repo} /opt/tekeche-api
cd /opt/tekeche-api
npm ci --omit=dev

%{ if env_secret_id != "" ~}
# Pull .env from OCI Vault
snap install oci-cli --classic || pip3 install oci-cli
oci secrets secret-bundle get \
  --secret-id "${env_secret_id}" \
  --query "data.\"secret-bundle-content\".content" \
  --raw-output | base64 -d > /opt/tekeche-api/.env
%{ else ~}
# Placeholder .env — update via OCI Vault or manually
cat > /opt/tekeche-api/.env <<ENVCFG
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb://${standby_private_ip}:27017/tekeche?replicaSet=${rs_name}
# Fill in remaining vars: JWT_SECRET, BREVO_*, GOOGLE_MAPS_KEY etc.
ENVCFG
%{ endif ~}

# ── PM2 ───────────────────────────────────────────────────────────────────────
cd /opt/tekeche-api
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash

# ── Nginx ─────────────────────────────────────────────────────────────────────
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/tekeche-selfsigned.key \
  -out    /etc/ssl/certs/tekeche-selfsigned.crt \
  -subj   "/CN=api.tekeche.com"

cat > /etc/nginx/sites-available/tekeche <<'NGINXCFG'
upstream api {
  server 127.0.0.1:5000;
  keepalive 32;
}
server {
  listen 80;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl http2;
  server_name api.tekeche.com;
  ssl_certificate     /etc/ssl/certs/tekeche-selfsigned.crt;
  ssl_certificate_key /etc/ssl/private/tekeche-selfsigned.key;
  ssl_protocols       TLSv1.2 TLSv1.3;
  ssl_ciphers         HIGH:!aNULL:!MD5;

  location /socket.io/ {
    proxy_pass         http://api;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade    $http_upgrade;
    proxy_set_header   Connection "upgrade";
    proxy_set_header   Host       $host;
    proxy_read_timeout 86400;
  }
  location / {
    proxy_pass            http://api;
    proxy_http_version    1.1;
    proxy_set_header      Host              $host;
    proxy_set_header      X-Real-IP         $remote_addr;
    proxy_set_header      X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header      X-Forwarded-Proto $scheme;
    proxy_connect_timeout 10s;
    proxy_read_timeout    60s;
  }
}
NGINXCFG

ln -sf /etc/nginx/sites-available/tekeche /etc/nginx/sites-enabled/tekeche
rm -f  /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

echo "$(date -u) tekeche-standby init complete" >> /var/log/tekeche-init.log
