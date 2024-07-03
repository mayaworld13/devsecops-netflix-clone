#!/bin/bash
sudo useradd --no-create-home --shell /bin/false prometheus
wget  https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar -xvf prometheus-2.53.0.linux-amd64.tar.gz
sudo mkdir -p /data /etc/prometheus
cd prometheus-2.53.0.linux-amd64
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
cd
rm -rf prometheus-2.53.0.linux-amd64.tar.gz
# Define the content of the Prometheus systemd unit file
SERVICE_FILE_CONTENT="[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/data \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries \\
  --web.listen-address=0.0.0.0:9090 \\
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
"

# Write the content to the systemd service file using sudo
sudo bash -c "cat <<EOF > /etc/systemd/system/prometheus.service
$SERVICE_FILE_CONTENT
EOF"

sudo systemctl enable prometheus
sudo systemctl start prometheus
