#!/bin/bash
set -eo pipefail

# Load utilities
source ./utils/env-checker.sh
source ./utils/install-progress.sh

echo "$CADDY_EMAIL"
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