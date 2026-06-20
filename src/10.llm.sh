#!/bin/sh
echo "Installing LLM tools..."

OLLAMA_DATA="/home/shared/ollama/.ollama"
OLLAMA_HOME="/usr/share/ollama/.ollama"
LMSTUDIO_SHARED="/home/shared/lmstudio"

# --- Ollama ---
curl -fsSL https://ollama.com/install.sh | sh

sudo mkdir -p "${OLLAMA_DATA}/models"
sudo usermod -aG shared ollama 2>/dev/null || true
sudo chown -R ollama:shared /home/shared/ollama
sudo chmod -R g+rwx /home/shared/ollama
sudo chmod -R g+s /home/shared/ollama

# Point the ollama daemon at shared storage (models, keys, logs, server.json)
echo "Configuring ollama daemon to use ${OLLAMA_DATA}..."
sudo systemctl stop ollama 2>/dev/null || true
if [ -L "${OLLAMA_HOME}" ]; then
  echo "Ollama data symlink already exists."
elif [ -d "${OLLAMA_HOME}" ] && [ -n "$(ls -A "${OLLAMA_HOME}" 2>/dev/null)" ]; then
  echo "Migrating existing ollama data to ${OLLAMA_DATA}..."
  sudo rsync -a "${OLLAMA_HOME}/" "${OLLAMA_DATA}/"
  sudo rm -rf "${OLLAMA_HOME}"
  sudo ln -s "${OLLAMA_DATA}" "${OLLAMA_HOME}"
else
  [ -e "${OLLAMA_HOME}" ] && sudo rm -rf "${OLLAMA_HOME}"
  sudo ln -s "${OLLAMA_DATA}" "${OLLAMA_HOME}"
fi
sudo chown -h ollama:shared "${OLLAMA_HOME}"
sudo systemctl daemon-reload
sudo systemctl restart ollama 2>/dev/null || true

# --- LM Studio ---
# LM Studio has no data-dir env var; symlink user paths to shared storage instead.
sudo mkdir -p \
  "${LMSTUDIO_SHARED}/.lmstudio/models" \
  "${LMSTUDIO_SHARED}/.lmstudio/bin" \
  "${LMSTUDIO_SHARED}/.lmstudio/.internal" \
  "${LMSTUDIO_SHARED}/cache/lm-studio" \
  "${LMSTUDIO_SHARED}/config/LM Studio"
sudo chown -R :shared "${LMSTUDIO_SHARED}"
sudo chmod -R g+rwx "${LMSTUDIO_SHARED}"
sudo chmod -R g+s "${LMSTUDIO_SHARED}"

link_to_shared() {
  target="$1"
  link="$2"
  mkdir -p "$(dirname "${link}")"
  if [ -e "${link}" ] && [ ! -L "${link}" ]; then
    echo "Migrating ${link} -> ${target}..."
    rsync -a "${link}/" "${target}/" 2>/dev/null || cp -a "${link}/." "${target}/"
    rm -rf "${link}"
  fi
  ln -sfn "${target}" "${link}"
}

echo "Configuring LM Studio symlinks for ${USER}..."
link_to_shared "${LMSTUDIO_SHARED}/.lmstudio" "${HOME}/.lmstudio"
link_to_shared "${LMSTUDIO_SHARED}/cache/lm-studio" "${HOME}/.cache/lm-studio"
link_to_shared "${LMSTUDIO_SHARED}/config/LM Studio" "${HOME}/.config/LM Studio"

# download gemma3 in background using ollama
# ollama pull gemma3 &

sudo apt install btop
