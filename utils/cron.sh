COMPOSE_DIR="/home/ubuntu/devops/"

SERVICE_FILE="/etc/systemd/system/poll-ecr.service"

cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=Poll ECR and update Docker services
After=network.target

[Service]
ExecStart=/home/ubuntu/devops/updater.sh
WorkingDirectory=$COMPOSE_DIR
EnvironmentFile=/home/ubuntu/devops/.env
User=ubuntu
Environment=HOME=/home/ubuntu
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log_success "Systemd service written to $SERVICE_FILE"

sudo systemctl daemon-reload

sudo systemctl enable poll-ecr.service

sudo systemctl start poll-ecr.service

log_success "ECR updater service is enabled"
