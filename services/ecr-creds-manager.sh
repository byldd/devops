amazon_ecr_credential_helper_installer() {
  case $1 in
    check)
      command -v docker-credential-ecr-login
      ;;
    install)
      sudo apt-get update -y
      sudo apt-get install -y amazon-ecr-credential-helper
      ;;
  esac
}
