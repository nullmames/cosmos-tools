# Read inputs
CHAIN_ID=$1

# Set variables
SERVICE_FILE=/etc/systemd/system/tmkms-${CHAIN_ID}.service
TOML_FILE=${HOME}/kms/config/tmkms-${CHAIN_ID}.toml

echo "[INFO] Writing $SERVICE_FILE..."

sudo tee ${SERVICE_FILE} > /dev/null <<EOF
[Unit]
Description=${CHAIN_ID} tmkms
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${HOME}
ExecStart=${HOME}/.cargo/bin/tmkms start -c ${TOML_FILE}
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tmkms-${CHAIN_ID}
sudo systemctl start tmkms-${CHAIN_ID}

echo "[INFO] Run journalctl -fu tmkms-${CHAIN_ID} for logs..."