# make sure to give executable rights to this file with - "chmod +x server_setup.sh"

INFISICAL_TOKEN="<infisical-service-token>"
INFISICAL_ENV="<staging | prod | dev>" # environment to fetch the env from
AWS_DEFAULT_REGION="<region>" # region where the ecr repo is hosted
AWS_URI="<aws-ecr-uri>"
AWS_REPO_NAME="<ecr-repo-name>" # the docker image to pull and run
DOMAIN_NAME="" # domain name to configure webserver
PORT=3000 # application port
LETS_ENCRYPT_USER_EMAIL=developer@byldd.com # for email notification from let's encrypt & certbot
APP_CONTAINER_NAME=frontend

echo "export INFISICAL_TOKEN=$INFISICAL_TOKEN" >> ~/.bashrc
source ~/.bashrc

# ==========================================================================================
# STEP 1 - Setup Docker
# ==========================================================================================

# https://docs.docker.com/engine/install/ubuntu/
# Add Docker's official GPG key:
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

# Give docker root access
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo su - $USER

# ==========================================================================================
# STEP 2 - Insall AWS CLI
# ==========================================================================================
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# ==========================================================================================
# STEP 3 - Setup Infisical
# ==========================================================================================
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt-get update && sudo apt-get install -y infisical

# ==========================================================================================
# STEP 4 - Login to AWS and Docker
# ==========================================================================================
infisical run --env="$INFISICAL_ENV" --path=/github/ -- aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "$AWS_URI"

# ==========================================================================================
# STEP 5 - Setup Caddy ( Webserver )
# ==========================================================================================
Caddyfile_Conf="
{
	email $LETS_ENCRYPT_USER_EMAIL
}

$DOMAIN_NAME {
	reverse_proxy http://$APP_CONTAINER_NAME:$PORT
}
"
mkdir -p caddy
echo "$Caddyfile_Conf" > caddy/Caddyfile


# Update Docker Compose

awk "{gsub(/_AWS_URI_/, \"$AWS_URI\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_AWS_REPO_NAME_/, \"$AWS_REPO_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_APP_CONTAINER_NAME_/, \"$APP_CONTAINER_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_PORT_/, \"$PORT\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_APP_CONTAINER_NAME_/, \"$USER\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml


# Run Docker Compose
docker compose up -d