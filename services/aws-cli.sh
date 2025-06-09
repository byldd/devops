aws_cli() {
  case $1 in
  check)
    command -v aws && command -v docker-credential-ecr-login
    ;;
  install)
    sudo apt-get update -y
    sudo apt install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    sudo apt install -y amazon-ecr-credential-helper
    ;;
  configure)
    sudo rm -rf aws awscliv2.zip
    ;;
  esac
}
