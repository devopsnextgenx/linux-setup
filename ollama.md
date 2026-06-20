### Ollama shared storage

Setup is automated in `src/1.shared.sh` (directories) and `src/10.llm.sh` (install + daemon config).

The ollama systemd service stores all data under `/usr/share/ollama/.ollama/`. The install script symlinks that path to `/home/shared/ollama/.ollama/` so models, keys, and server config are shared across users via the `shared` group.

To verify:

```bash
ls -la /usr/share/ollama/.ollama
systemctl status ollama
```

Optional systemd overrides (already applied on this machine):

```bash
sudo systemctl edit ollama.service

# Example overrides
# Environment="OLLAMA_HOST=0.0.0.0:11434"
# Environment="OLLAMA_NUM_PARALLEL=2"
```

### LM Studio shared storage

LM Studio does not support a data-directory environment variable. `src/10.llm.sh` symlinks each user's paths to shared storage:

| User path | Shared path |
| --- | --- |
| `~/.lmstudio` | `/home/shared/lmstudio/.lmstudio` |
| `~/.cache/lm-studio` | `/home/shared/lmstudio/cache/lm-studio` |
| `~/.config/LM Studio` | `/home/shared/lmstudio/config/LM Studio` |

For additional users, re-run the LM Studio symlink section from `src/10.llm.sh` or run:

```bash
LMSTUDIO_SHARED="/home/shared/lmstudio"
link_to_shared() {
  target="$1"; link="$2"
  mkdir -p "$(dirname "${link}")"
  [ -e "${link}" ] && [ ! -L "${link}" ] && rsync -a "${link}/" "${target}/" && rm -rf "${link}"
  ln -sfn "${target}" "${link}"
}
link_to_shared "${LMSTUDIO_SHARED}/.lmstudio" "${HOME}/.lmstudio"
link_to_shared "${LMSTUDIO_SHARED}/cache/lm-studio" "${HOME}/.cache/lm-studio"
link_to_shared "${LMSTUDIO_SHARED}/config/LM Studio" "${HOME}/.config/LM Studio"
```
