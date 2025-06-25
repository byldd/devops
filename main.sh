#!/bin/bash
set -eo pipefail

# ================================
# Utility Sources
# ================================
source ./utils/loggers.sh
source ./utils/install-progress.sh
source ./utils/env-checker.sh

# ================================
# Sudo Check
# ================================
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo or as root."
    log_info "Run it like: sudo bash main.sh"
    exit 1
fi

LOCAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$LOCAL_USER")

# ================================
# Firebase Auth Check
# ================================
if [ "$AUTH_TYPE" = "FIREBASE" ]; then
    FIREBASE_FILE="$USER_HOME/devops/firebase-cert.json"
    if [ ! -f "$FIREBASE_FILE" ]; then
        log_error "Firebase cert missing. Please place 'firebase-cert.json' at $FIREBASE_FILE"
        exit 1
    fi
fi

# ================================
# Installer Services
# ================================
source ./services/docker.sh
source ./services/aws-cli.sh
source ./services/caddy.sh

install_with_progress "AWS CLI" aws_cli
install_with_progress "Caddy" caddy_installer
install_with_progress "Docker" docker_installer

# ================================
# Auto-Updater Setup
# ================================
log_info "Setting up Autoupdater:"
source ./utils/cron.sh
chmod a+x ./utils/{env-checker.sh,loggers.sh} updater.sh
sudo systemctl restart caddy
log_success "All services are installed and configured successfully"
echo "-----------------------"
echo

# ================================
# Logger (Dozzle) Setup
# ================================
log_info "Setting up Dozzle logger:"
docker run -it --rm amir20/dozzle generate "$DOZZLE_USERNAME" \
  --password "$DOZZLE_PASSWORD" \
  --email "$DOZZLE_EMAIL" \
  --name "$DOZZLE_USERNAME" > users.yml
log_success "Dozzle configured successfully"
echo "-----------------------"
echo

# ================================
# DNS Configuration Reminder
# ================================
log_info "---- IMPORTANT NEXT STEP ----"
EC2_IP=$(curl -s https://checkip.amazonaws.com)
log_info "Add these DNS records:"
echo -e "  A record: ${YELLOW}${BACKEND_DOMAIN}   -> ${EC2_IP}${NC}"
echo -e "  A record: ${YELLOW}${FRONTEND_DOMAIN}  -> ${EC2_IP}${NC}"
echo -e "  A record: ${YELLOW}${DOZZLE_DOMAIN}    -> ${EC2_IP}${NC}"
echo
log_success "Once DNS is updated, your setup will be live!"
echo "---- Stay Happy ----"
echo

# ================================
# Exiting the current shell
# ================================
exec su - "$LOCAL_USER"
