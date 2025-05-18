infisical_installer() {
  case $1 in
    check)
      command -v infisical
      ;;
    install)
      # Install Infisical CLI via official install script
      curl -fsSL https://cli.infisical.com/install.sh | bash
      ;;
  esac
}
