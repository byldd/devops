######################################################################################
# make sure to give executable rights to this file with - "chmod +x server_setup.sh" #
######################################################################################

INFISICAL_CLIENT_ID=xxx
INFISICAL_CLIENT_SECRET=xxx
INFISICAL_PROJECT_ID=xxx
INFISICAL_ENV="staging" # environment to fetch the env from

AWS_DEFAULT_REGION=xxx # region where the ecr repo is hosted
AWS_URI=xxx
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

FE_AWS_REPO_NAME=xxx # the docker image to pull and run
BE_AWS_REPO_NAME=xxx # the docker image to pull and run

FE_DOMAIN_NAME=xxx # frontend domain name to configure webserver
BE_DOMAIN_NAME=xxx # backend domain name to configure webserver
PORTAINER_DOMAIN=xxx

FE_PORT=3000 # frontend application port
BE_PORT=8000 # backend application port

LETS_ENCRYPT_USER_EMAIL=developer@byldd.com # for email notification from let's encrypt & certbot
FE_APP_CONTAINER_NAME=frontend
BE_APP_CONTAINER_NAME=backend


# =======================================================================
# Check if infisical client id exists or not in bashrc
# =======================================================================
if grep -qR "INFISICAL_CLIENT_ID" $HOME/.bashrc; 
then
	echo "skipped adding infisical client id to bashrc"
else
  echo "export INFISICAL_CLIENT_ID=$INFISICAL_CLIENT_ID" >> $HOME/.bashrc
  source $HOME/.bashrc
	echo "added infisical client id to bashrc"
fi

# =======================================================================
# Check if infisical client secret exists or not in bashrc
# =======================================================================
if grep -qR "INFISICAL_CLIENT_SECRET" $HOME/.bashrc; 
then
	echo "skipped adding infisical client secret to bashrc"
else
  echo "export INFISICAL_CLIENT_SECRET=$INFISICAL_CLIENT_SECRET" >> $HOME/.bashrc
  source $HOME/.bashrc
	echo "added infisical client secret to bashrc"
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
STATUS="$(systemctl is-active docker)"
if [ "${STATUS}" = "active" ]; then
  echo "Skipped setting up docker"
else
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
  # sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo su - $USER
fi

# ==========================================================================================
# STEP 2 - Insall AWS ECR credentials manager
# ==========================================================================================
sudo apt install -y amazon-ecr-credential-helper

# ==========================================================================================
# STEP 3 - Configure Caddy ( webserver )
# ==========================================================================================

DOCKER_CONFIG="
{
  \"credsStore\": \"ecr-login\",
  \"credHelpers\": {
		\"$AWS_URI\": \"ecr-login\"
	}
}
"

mkdir -p $HOME/.docker
touch $HOME/.docker/config.json
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

$PORTAINER_DOMAIN {
  reverse_proxy http://portainer:9000
}
"
mkdir -p $HOME/caddy
echo "$Caddyfile_Conf" > $HOME/caddy/Caddyfile


# Update Docker Compose -> INFISICAL PROJECT ID
awk "{gsub(/_INFISICAL_PROJECT_ID_/, \"$INFISICAL_PROJECT_ID\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

# Update Docker Compose -> AWS URI
awk "{gsub(/_AWS_URI_/, \"$AWS_URI\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

# Update Docker Compose -> INFISICAL ENV
awk "{gsub(/_INFISICAL_ENV_/, \"$INFISICAL_ENV\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

# Update Docker Compose -> AWS REPO NAME
awk "{gsub(/_FE_AWS_REPO_NAME_/, \"$FE_AWS_REPO_NAME\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

awk "{gsub(/_BE_AWS_REPO_NAME_/, \"$BE_AWS_REPO_NAME\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

# Update Docker Compose -> Container Name
awk "{gsub(/_FE_APP_CONTAINER_NAME_/, \"$FE_APP_CONTAINER_NAME\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

awk "{gsub(/_BE_APP_CONTAINER_NAME_/, \"$BE_APP_CONTAINER_NAME\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

# Update Docker Compose -> Container Port
awk "{gsub(/_FE_PORT_/, \"$FE_PORT\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml

awk "{gsub(/_BE_PORT_/, \"$BE_PORT\"); print}" $HOME/docker-compose.yml > temp_file && mv temp_file $HOME/docker-compose.yml


# Mount aws ecr credential helper volume to host machine so that it can be used inside watchtower for ecr creds helper installation
# ref: https://containrrr.dev/watchtower/private-registries/#credential_helpers
docker run  -d --rm --name aws-cred-helper --volume helper:/go/bin tanishbyldd/aws-ecr-dock-cred-helper

docker volume create portainer_data

# Run Docker Compose
docker compose up -d