amazon_ecr_credential_helper_installer() {
  case $1 in
    check)
      command -v docker-credential-ecr-login
      ;;
    install)
      curl -fsSL https://d1vvhvl2y92vvt.cloudfront.net/amazon-ecr-credential-helper.gpg | sudo gpg --dearmor -o /usr/share/keyrings/amazon.gpg
      echo "deb [signed-by=/usr/share/keyrings/amazon.gpg] https://d1vvhvl2y92vvt.cloudfront.net stable main" | sudo tee /etc/apt/sources.list.d/amazon-ecr-helper.list
      sudo apt-get update
      sudo apt-get install -y amazon-ecr-credential-helper
      ;;
  esac
}
