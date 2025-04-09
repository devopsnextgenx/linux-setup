### override ollama.service
```bash
sudo systemctl edit ollama.service

# Add below content
# Environment="OLLAMA_MODELS=/home/shared/ollama/.ollama/models"
# Environment="OLLAMA_HOST=0.0.0.0:11434"
# Environment="OLLAMA_NUM_PARALLEL=2"


sudo usermod -a -G shared ollama

```