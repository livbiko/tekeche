#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# ── System packages ────────────────────────────────────────────────────────
apt-get update -qq
apt-get install -y -qq curl gnupg nginx git openssl

# ── Node.js 20 ────────────────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2

# ── MongoDB 8 (replica set member, never primary) ─────────────────────────
# Must match on-prem's version (8.3.4) -- replica sets can't tolerate much
# version skew between members; a 8.0 vs 8.3 gap caused every replication
# auth handshake to be abandoned by the primary.
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.3 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.3.list
apt-get update -qq && apt-get install -y mongodb-org

# Replica set members need a shared keyFile for internal cluster auth --
# mongod refuses to start with authorization+replication enabled without
# one. Must be byte-identical to on-prem's keyfile (same replica set).
cat > /etc/mongo-keyfile <<KEYFILE
${mongodb_keyfile_content}
KEYFILE
chown mongodb:mongodb /etc/mongo-keyfile
chmod 600 /etc/mongo-keyfile

cat > /etc/mongod.conf <<MONGOCFG
storage:
  dbPath: /var/lib/mongodb
net:
  port: 27017
  bindIp: 127.0.0.1,${private_ip}
replication:
  replSetName: "${mongodb_rs_name}"
security:
  authorization: enabled
  keyFile: /etc/mongo-keyfile
MONGOCFG

systemctl enable mongod && systemctl start mongod

%{ if run_redis_data_node }
# ── Redis (replica of on-prem) ────────────────────────────────────────────
# NOTE (2026-08-01): this box is a genuine Sentinel-monitored data replica
# (one of 3: BikoDC, BikoDC1, this node) -- the plain `replicaof` line below
# is what first-boot cloud-init gives it, but the live Sentinel mesh
# (SENTINEL_HOSTS, sentinel-pass, systemd unit, quorum=4 across 7 nodes) was
# layered on afterward through a series of manual fixes documented in
# MAINTENANCE_LOG.md's 2026-08-01 00:24 and 2026-07-11 16:28 entries -- not
# fully reproducible from this template alone. A rebuild of this node needs
# to replay those steps (or a proper runbook derived from them), not just
# re-run this cloud-init.
apt-get install -y redis-server
sed -i "s/^bind .*/bind 127.0.0.1 ${private_ip}/" /etc/redis/redis.conf
echo "replicaof ${onprem_nlb_vip} 6379" >> /etc/redis/redis.conf
echo "replica-read-only yes"                 >> /etc/redis/redis.conf
systemctl enable redis-server && systemctl restart redis-server
%{ endif }

# ── Clone tekeche-api ─────────────────────────────────────────────────────
git clone ${github_clone_url} /opt/tekeche-api
cd /opt/tekeche-api
npm ci --omit=dev

%{ if app_env_secret_id != "" }
# Pull .env from OCI Vault
apt-get install -y -qq python3-pip
pip3 install -q oci-cli
oci secrets secret-bundle get --auth instance_principal --secret-id "${app_env_secret_id}" \
  --query "data.\"secret-bundle-content\".content" --raw-output \
  | base64 -d > /opt/tekeche-api/.env
%{ else }
cat > /opt/tekeche-api/.env <<ENVCFG
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb://${private_ip}:27017/tekeche?replicaSet=${mongodb_rs_name}
ENVCFG
%{ endif }

# ── PM2 ───────────────────────────────────────────────────────────────────
# Not using ecosystem.config.js here: it hardcodes Windows paths for the
# on-prem cwd/log files and also defines staging/local apps that have no
# business running on this standby.
# Cluster mode (-i max) matches production's PM2 cluster mode so the
# standby can actually use all ${standby_ocpus} OCPUs during failover
# instead of running as a single Node process.
cd /opt/tekeche-api
pm2 start server.js --name tekeche-api -i max
pm2 save
# Best-effort: sets up auto-start-on-reboot. Not fatal if the piped
# suggested command doesn't parse cleanly -- app is already running,
# and nginx below still needs to start regardless.
pm2 startup systemd -u root --hp /root | tail -1 | bash || true

# ── Nginx reverse proxy ───────────────────────────────────────────────────
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/tekeche-selfsigned.key \
  -out /etc/ssl/certs/tekeche-selfsigned.crt \
  -subj "/CN=api.tekeche.com"

cat > /etc/nginx/sites-available/tekeche <<NGINXCFG
upstream api {
  server 127.0.0.1:5000;
  keepalive 32;
}

server {
  listen 80;
  return 301 https://\$host\$request_uri;
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
    proxy_set_header   Upgrade \$http_upgrade;
    proxy_set_header   Connection "upgrade";
    proxy_set_header   Host \$host;
    proxy_read_timeout 86400;
  }

  location / {
    proxy_pass         http://api;
    proxy_http_version 1.1;
    proxy_set_header   Host              \$host;
    proxy_set_header   X-Real-IP         \$remote_addr;
    proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto \$scheme;
    proxy_connect_timeout 10s;
    proxy_read_timeout    60s;
  }
}
NGINXCFG

ln -sf /etc/nginx/sites-available/tekeche /etc/nginx/sites-enabled/tekeche
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

# ── Open the OS firewall ────────────────────────────────────────────────────
# Oracle's default image ships iptables with only port 22 allowed inbound
# and a catch-all REJECT for everything else -- OCI Security Lists are a
# separate outer layer and don't override this. Without these rules, traffic
# that Security Lists correctly allow (LB health checks on 443, on-prem
# MongoDB/Redis replication on 27017/6379) still gets rejected at the OS
# level even though the actual service is up and listening.
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 27017 -j ACCEPT
%{ if run_redis_data_node }
iptables -I INPUT -p tcp --dport 6379 -j ACCEPT
%{ endif }
netfilter-persistent save || true

echo "Tekeche standby ready" > /var/log/tekeche-init.log
