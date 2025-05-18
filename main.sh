#!/bin/bash
set -eo pipefail

# Load shared functions
source ./utils/utils.sh

# Load installers
source ./services/docker.sh
source ./services/ecr-creds-manager.sh
source ./services/caddy.sh
source ./services/infisical.sh
# Add more as needed

# Run installations
install_with_progress "Docker" docker_installer
install_with_progress "Amazon-ECR-Credential-Helper" amazon_ecr_credential_helper_installer
install_with_progress "Caddy" caddy_installer
install_with_progress "Infisical" infisical_installer