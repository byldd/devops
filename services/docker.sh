docker_installer() {
  case $1 in
  check)
    command -v docker compose
    ;;

  install)
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      gpg

    sudo mkdir -p /etc/apt/keyrings

    # Ensure GPG key is saved
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
        exit 1
      }

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin \
      docker-compose

    sudo systemctl enable docker
    sudo systemctl start docker
    ;;

  configure)
    LOCAL_USER="${SUDO_USER:-$USER}"
    HOME_DIR=$(eval echo "~$LOCAL_USER")
    DOCKER_DIR="$HOME_DIR/.docker"
    DOCKER_CONF="$DOCKER_DIR/config.json"

    # Add user to docker group
    sudo usermod -aG docker "$LOCAL_USER"

    sudo mkdir -p "$DOCKER_DIR"
    sudo chown -R "$LOCAL_USER:$LOCAL_USER" "$DOCKER_DIR"

    cat <<EOF | sudo tee "$DOCKER_CONF" > /dev/null
{
  "credsStore": "ecr-login",
  "credHelpers": {
    "$ECR_BASE_URI": "ecr-login"
  }
}
EOF

    sudo chown "$LOCAL_USER:$LOCAL_USER" "$DOCKER_CONF"
    ;;
  esac
}
