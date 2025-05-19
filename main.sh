#!/bin/bash
set -eo pipefail

# Load utilities
source ./utils/env-checker.sh
source ./utils/install-progress.sh

# =======================================================================
# Firebase cert file exists check
# NOTE: This is for the old boilerplate where firebase-cert file is needed
# to run the backend. Uncomment this if needed.
# =======================================================================
# if ! [ -f $HOME/firebase-cert.json ]; then
#   echo "firebase cert does not exists. Please paste it in $HOME directory. Name of the file should be \'firebase-cert.json\'"
#   exit 1;
# fi

# Load services
source ./services/docker.sh
source ./services/ecr-creds-manager.sh
source ./services/caddy.sh
source ./services/infisical.sh

# Run installations
install_with_progress "Docker" docker_installer
install_with_progress "Amazon-ECR-Credential-Helper" amazon_ecr_credential_helper_installer
install_with_progress "Caddy" caddy_installer
install_with_progress "Infisical" infisical_installer

# Configure Watchtower
# Mount aws ecr credential helper volume to host machine so that it can be used inside watchtower for ecr creds helper installation
# ref: https://containrrr.dev/watchtower/private-registries/#credential_helpers
echo "✨ Step : Configuring watchtower"
docker run  -d --rm --name aws-cred-helper --volume helper:/go/bin tanishbyldd/aws-ecr-dock-cred-helper
echo "✔️  Watchtower configuration completed"
echo "-----------------------"
echo
echo " 🚀 All services are configured successfully"