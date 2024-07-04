#!/bin/bash

# Step 1: Create system user for node_exporter
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false \
    node_exporter

# Step 2: Download and install Node Exporter
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64

# Step 3: Create systemd service file for Node Exporter
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
EOF

# Step 4: Enable and start Node Exporter service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Step 5: Update Prometheus configuration to scrape node exporter
sudo tee -a /etc/prometheus/prometheus.yml > /dev/null <<EOF

# Node Exporter
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Step 6: Validate Prometheus configuration
sudo promtool check config /etc/prometheus/prometheus.yml

# Step 7: Reload Prometheus to apply configuration
curl -X POST http://localhost:9090/-/reload
