aws_cli() {
  case $1 in
  check)
    command -v aws
    ;;
  install)
    sudo apt install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ;;
  configure)
    sudo rm -rf aws awscliv2.zip
    ;;
  esac
}
