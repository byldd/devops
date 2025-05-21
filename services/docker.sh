docker_installer() {
  case $1 in
  check)
    command -v docker
    ;;
  install)
    sudo apt-get update -y
    sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ;;
  configure)
    sudo usermod -aG docker $USER
    sudo su - $USER

    DOCKER_DIR="$HOME/.docker"

    DOCKER_CONF="$DOCKER_DIR/config.json"

    mkdir -p "$DOCKER_DIR"

    if [ -f "$DOCKER_CONF" ]; then
      sudo rm -f "$DOCKER_CONF"
    fi

    #create a new Caddyfile with our .envs
    cat <<EOF >"$DOCKER_CONF"
{
  "credsStore": "ecr-login",
  "credHelpers": {
    "$ECR_BASE_URI": "ecr-login"
  }
}
EOF

    # Set correct permissions
    chown root:root "$DOCKER_CONF"
    chmod 644 "$DOCKER_CONF"
    ;;
  esac
}
