#!/bin/bash
set -eo pipefail

# Load utilities
source ./utils/loggers.sh
source ./utils/env-checker.sh
source ./utils/install-progress.sh

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
source ./services/ecr-creds-manager.sh
source ./services/caddy.sh

# Run installations
install_with_progress "Amazon-ECR-Credential-Helper" amazon_ecr_credential_helper_installer
install_with_progress "Caddy" caddy_installer
install_with_progress "Docker" docker_installer

# Configure Watchtower
# Mount aws ecr credential helper volume to host machine so that it can be used inside watchtower for ecr creds helper installation
# ref: https://containrrr.dev/watchtower/private-registries/#credential_helpers
log_info "Setting up watchtower :"
docker run -d --rm --name aws-cred-helper --volume helper:/go/bin tanishbyldd/aws-ecr-dock-cred-helper
log_success "Watchtower configuration completed"
echo "-----------------------"
echo
sudo systemctl restart caddy
log_success "All services are installed and configured successfully"
log_info "---- IMPORTANT NEXT STEP ----"
log_info "Add the following DNS A records to your domain provider:"
EC2_IP=$(curl -s http://checkip.amazonaws.com)

log_info "Point them to your EC2 instance public IP: ${YELLOW}${EC2_IP}${NC}"
echo
log_info "Example A records:"
echo -e "   ${YELLOW}${BACKEND_DOMAIN}     A     ${EC2_IP}${NC}"
echo -e "   ${YELLOW}${FRONTEND_DOMAIN} A     ${EC2_IP}${NC}"
echo
log_success "Once done, your setup will be fully live and ready to use!"
echo
