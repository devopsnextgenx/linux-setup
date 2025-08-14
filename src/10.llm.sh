#!/bin/sh
echo "Installing LLM tools..."
curl -fsSL https://ollama.com/install.sh | sh
mkdir -p /home/shared/ollama/.ollama/models
sudo usermod -a -G shared ollama
sudo chown -R :shared /home/shared/ollama
sudo chmod -R g+s /home/shared/ollama

# download gemma3 in background using ollama
# ollama pull gemma3 &

mkdir -p /home/shared/lmstudio/.lmstudio/models

sudo apt install btop