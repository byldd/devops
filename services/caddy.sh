caddy_installer() {
  case $1 in
  check)
    command -v caddy
    ;;
  install)
    sudo apt-get update -y
    sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https

    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' |
      sudo tee /etc/apt/sources.list.d/caddy-stable.list

    sudo apt-get update -y
    sudo apt-get install -y caddy
    ;;
  configure)
    CADDY_DIR="/etc/caddy"

    CADDY_FILE="$CADDY_DIR/Caddyfile"

    mkdir -p "$CADDY_DIR"

    if [ -f "$CADDY_FILE" ]; then
      sudo rm -f "$CADDY_FILE"
    fi

    #create a new Caddyfile with our .envs
    cat <<EOF >"$CADDY_FILE"
{
  email $CADDY_EMAIL
}

$FRONTEND_DOMAIN {
  reverse_proxy http://localhost:$FRONTEND_PORT
}

$BACKEND_DOMAIN {
  reverse_proxy http://localhost:$BACKEND_PORT
}
EOF

    # Set correct permissions
    chown root:root "$CADDY_FILE"
    chmod 644 "$CADDY_FILE"
    ;;
  esac
}
