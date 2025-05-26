#!/bin/bash
set -eo pipefail

# Load utilities
source ./utils/loggers.sh
source ./utils/install-progress.sh

#sudo check
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo or as root."
    log_info "Please run it like: sudo bash main.sh"
    exit 1
fi

#checking env
source ./utils/env-checker.sh

if [ "$AUTH_TYPE" = "FIREBASE" ]; then
    LOCAL_USER="${SUDO_USER:-$USER}"

    FIREBASE_DIR="/home/$LOCAL_USER/devops"

    FIREBASE_FILE="$FIREBASE_DIR/firebase-cert.json"
    if ! [ -f "$FIREBASE_FILE" ]; then
        log_error "firebase cert does not exists. Please paste it in $HOME directory. Name of the file should be \'firebase-cert.json\'"
        exit 1
    fi
fi

# Load services
source ./services/docker.sh
source ./services/aws-cli.sh
source ./services/caddy.sh

# Run installations
install_with_progress "AWS Cli" aws_cli
install_with_progress "Caddy" caddy_installer
install_with_progress "Docker" docker_installer

# Logging in ECR
log_info "Logging into AWS ECR..."
aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "${ECR_BASE_URI%%/*}"
log_success "Logged into ECR Successfully"

# Configure Auto Updater
log_info "Setting up Autoupdater :"
source ./utils/cron.sh
echo "-----------------------"
echo
sudo systemctl restart caddy

log_success "All services are installed and configured successfully"

log_info "---- IMPORTANT NEXT STEP ----"
log_info "Add the following DNS records to your domain provider:"
EC2_IP=$(curl -s https://checkip.amazonaws.com)
log_info "DNS records:"
echo -e "  type: A    value: ${YELLOW}${BACKEND_DOMAIN}   ip: ${EC2_IP}${NC} "
echo -e "  type: A    value: ${YELLOW}${FRONTEND_DOMAIN}  ip: ${EC2_IP}${NC} "
echo
log_success "Once done, your setup will be fully live and ready to use!"
sudo chmod +x updater.sh
echo
