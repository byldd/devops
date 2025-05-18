infisical_installer() {
  case $1 in
    check)
      command -v infisical
      ;;
    install)
      curl -1sLf \
        'https://artifacts-cli.infisical.com/setup.deb.sh' \
        | sudo -E bash
      sudo apt-get update && sudo apt-get install -y infisical
      ;;
  esac
}
