docker_installer() {
  case $1 in
  check)
    command docker compose version
    ;;
  install)
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
    sudo systemctl enable docker
    sudo systemctl start docker
    ;;
  esac
}
