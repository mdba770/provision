#! /bin/bash
################ BECAME ROOT ################################################
sudo su 
################ GENERAL INSTALATIONS & NGINX ###############################
setenforce 0
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
yum -y update && yum -y install epel-release && yum -y install nano wget screen nano vim gcc-c++ make git nginx
systemctl start nginx && systemctl enable nginx 
echo "server {
    listen 80;
    server_name   app.langosh.io;
    error_log /var/log/nginx/app_error.log;
    access_log /var/log/nginx/app_access.log;

    location / {
        proxy_set_header   X-Forwarded-For "\$remote_addr";
        proxy_set_header   Host "\$http_host";
        proxy_pass         http://localhost:5001;
    }
}
" > /etc/nginx/conf.d/app.conf
echo "server {
    listen 80;
    server_name   graf.langosh.io;
    error_log /var/log/nginx/gref_error.log;
    access_log /var/log/nginx/graf_access.log;

    location / {
        proxy_set_header   X-Forwarded-For "\$remote_addr";
        proxy_set_header   Host "\$http_host";
        proxy_pass         http://localhost:3000;
    }
}
" > /etc/nginx/conf.d/graf.conf
systemctl reload nginx
################################# INSTALL PROMETHEUS ####################################################
useradd -m -s /bin/bash prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.21.0/prometheus-2.21.0.linux-amd64.tar.gz
tar -xzvf prometheus-2.21.0.linux-amd64.tar.gz
mv  prometheus-2.21.0.linux-amd64 /home/prometheus/prometheus
chown -R prometheus:prometheus /home/prometheus
echo "[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Restart=on-failure

#Change this line if you download the 
#Prometheus on different path user
ExecStart=/home/prometheus/prometheus/prometheus \
  --config.file=/home/prometheus/prometheus/prometheus.yml \
  --storage.tsdb.path=/home/prometheus/prometheus/data

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/prometheus.service
systemctl daemon-reload
systemctl start prometheus && systemctl enable prometheus
############################# NODE_EXPORTER ############################################################
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz 
tar -xzvf node_exporter-1.0.1.linux-amd64.tar.gz 
mv node_exporter-1.0.1.linux-amd64 /home/prometheus/node_exporter
chown -R prometheus:prometheus /home/prometheus
echo "[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target" > /etc/systemd/system/node_exporter.service
echo "
  - job_name: 'node_exporter'
    static_configs:
    - targets: ['localhost:9100']" >> /home/prometheus/prometheus/prometheus.yml
systemctl daemon-reload
systemctl start node_exporter && systemctl enable node_exporter
######################## INSTALL GRAFANA ############################
echo "[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt" > /etc/yum.repos.d/grafana.repo
yum -y install grafana
systemctl start grafana-server && systemctl enable grafana-server
############## NODEJS & APP #########################################
echo "[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc" > /etc/yum.repos.d/mongodb-org-4.2.repo
sudo yum -y install -y mongodb-org
systemctl start mongod.service && systemctl enable mongod.service 
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
yum -y install nodejs && npm install pm2 -g 
mkdir /app && cd /app && git clone https://github.com/mdba770/app.git
echo "
MONGODB_CONNECTION_STRING=mongodb://127.0.0.1/whatsapp
PORT=5001
ACCOUNT_SID=<YOUR_ACCOUNT_SID>
AUTH_TOKEN=<YOUR_AUTH_TOKEN>" > /app/app/.env
 cd /app/app  && npm install && pm2 start npm --name "app" -- start && pm2 startup
############## MONGODB ##############################################
