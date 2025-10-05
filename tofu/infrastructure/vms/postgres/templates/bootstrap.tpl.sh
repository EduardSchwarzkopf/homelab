
mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update

apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

usermod -aG docker "$(id -nu 1000)"

su - ubuntu -c "cd /home/ubuntu && docker compose up -d"

chown 1000:1000 -R ${MOUNT_PATH}

chown 5050:5050 -R ${PGADMIN_DATA_PATH}

echo "bootstrap done"