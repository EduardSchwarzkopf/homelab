
 apt install -y nvidia-cuda-toolkit
 nvidia-smi

curl -fsSL https://ollama.com/install.sh | sh

# edit service to allow connections:
Environment="OLLAMA_HOST=0.0:11434"

systemctl daemon-reload