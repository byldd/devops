# make sure to give executable rights to this file with - "chmod +x server_setup.sh"

INFISICAL_TOKEN="st.67e05bf8-c01d-40c5-94de-7603f5ebdaa9.9a6f9c214f6623b9a62788018611dc9f.2ec3058fd25959b20bffa7697e4f525e"
INFISICAL_ENV="staging" # environment to fetch the env from

AWS_DEFAULT_REGION="us-east-2" # region where the ecr repo is hosted
AWS_URI="035117277814.dkr.ecr.us-east-2.amazonaws.com"

FE_AWS_REPO_NAME="rhefy-fe:staging" # the docker image to pull and run
BE_AWS_REPO_NAME="rhefy-be:staging" # the docker image to pull and run

FE_DOMAIN_NAME="test.decimal-app.com" # frontend domain name to configure webserver
BE_DOMAIN_NAME="test-api.decimal-app.com" # backend domain name to configure webserver

FE_PORT=3000 # frontend application port
BE_PORT=8000 # backend application port

LETS_ENCRYPT_USER_EMAIL=developer@byldd.com # for email notification from let's encrypt & certbot
FE_APP_CONTAINER_NAME=frontend
BE_APP_CONTAINER_NAME=backend



# =======================================================================
# Check if infisical token exists or not in bashrc
# =======================================================================
if grep -qR "INFISICAL_TOKEN" $HOME/.bashrc; 
then
	echo "skipped adding infisical token to bashrc"
else
  echo "export INFISICAL_TOKEN=$INFISICAL_TOKEN" >> $HOME/.bashrc
  source $HOME/.bashrc
	echo "added infisical token to bashrc"
fi

# =======================================================================
# Check if aws secret key exists or not in bashrc
# =======================================================================
if grep -qR "AWS_SECRET_ACCESS_KEY" $HOME/.bashrc; 
then
	echo "skipped adding aws secret key to bashrc"
else
  echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> $HOME/.bashrc
  source $HOME/.bashrc
	echo "added aws secret key to bashrc"
fi

# =======================================================================
# Check if aws access key exists or not in bashrc
# =======================================================================
if grep -qR "AWS_ACCESS_KEY_ID" $HOME/.bashrc; 
then
	echo "skipped adding aws access key to bashrc"
else
  echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> $HOME/.bashrc
  source $HOME/.bashrc
	echo "added aws access key to bashrc"
fi


# =======================================================================
# Check if firebase-cert exists or not
# =======================================================================
if ! [ -f $HOME/firebase-cert.json ]; then
  echo "firebase cert does not exists. Please paste it in $HOME directory. Name of the file should be \'firebase-cert.json\'"
  exit 1;
fi

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
# STEP 2 - Insall AWS ECR credentials manager
# ==========================================================================================
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo apt install -y unzip
# unzip awscliv2.zip
# sudo ./aws/install
sudo apt update
sudo apt install -y amazon-ecr-credential-helper

# ==========================================================================================
# STEP 3 - Setup Infisical
# ==========================================================================================
# curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
# sudo apt-get update && sudo apt-get install -y infisical

# ==========================================================================================
# STEP 4 - Login to AWS and Docker
# ==========================================================================================
# infisical run --env="$INFISICAL_ENV" --path=/github/ -- aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "$AWS_URI"
DOCKER_CONFIG="
{
  \"credsStore\": \"ecr-login\",
  \"credHelpers\": {
		\"$AWS_URI\": \"ecr-login\"
	}
}
"
echo "$DOCKER_CONFIG" > ${HOME}/.docker/config.json

# ==========================================================================================
# STEP 5 - Setup Caddy ( Webserver )
# ==========================================================================================
Caddyfile_Conf="
{
	email $LETS_ENCRYPT_USER_EMAIL
}

$FE_DOMAIN_NAME {
	reverse_proxy http://$FE_APP_CONTAINER_NAME:$FE_PORT
}

$BE_DOMAIN_NAME {
	reverse_proxy http://$BE_APP_CONTAINER_NAME:$BE_PORT
}
"
mkdir -p $HOME/caddy
echo "$Caddyfile_Conf" > $HOME/caddy/Caddyfile


# Update Docker Compose -> AWS URI
awk "{gsub(/_AWS_URI_/, \"$AWS_URI\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

# Update Docker Compose -> INFISICAL ENV
awk "{gsub(/_INFISICAL_ENV_/, \"$INFISICAL_ENV\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

# Update Docker Compose -> AWS REPO NAME
awk "{gsub(/_FE_AWS_REPO_NAME_/, \"$FE_AWS_REPO_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_BE_AWS_REPO_NAME_/, \"$BE_AWS_REPO_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

# Update Docker Compose -> Container Name
awk "{gsub(/_FE_APP_CONTAINER_NAME_/, \"$FE_APP_CONTAINER_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_BE_APP_CONTAINER_NAME_/, \"$BE_APP_CONTAINER_NAME\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

# Update Docker Compose -> Container Port
awk "{gsub(/_FE_PORT_/, \"$FE_PORT\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml

awk "{gsub(/_BE_PORT_/, \"$BE_PORT\"); print}" docker-compose.yml > temp_file && mv temp_file docker-compose.yml


# Mount aws ecr credential helper volume to host machine so that it can be used inside watchtower for ecr creds helper installation
# ref: https://containrrr.dev/watchtower/private-registries/#credential_helpers
docker run  -d --rm --name aws-cred-helper --volume helper:/go/bin tanishbyldd/aws-ecr-dock-cred-helper

# Run Docker Compose
docker compose up -d