ubuntu-drivers autoinstall
curl -fsSL https://ollama.com/install.sh | sh

MODELS_PATH=${MOUNT_PATH}/models
mkdir -p $MODELS_PATH /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/custom.conf > /dev/null <<EOT
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=$MODELS_PATH"
EOT

chown -R ollama:ollama $MODELS_PATH

systemctl daemon-reload

reboot