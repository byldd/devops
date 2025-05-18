#!/bin/bash
set -eo pipefail

# Load shared functions
source ./utils/utils.sh

# Load installers
source ./services/docker.sh
# Add more as needed

# Run installations
install_with_progress "Docker" docker_installer
