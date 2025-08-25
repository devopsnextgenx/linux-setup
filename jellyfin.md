### Update startup file
```bash
sudo systemctl edit jellyfin

[Unit]
Description=Jellyfin Media Server
After=network.target

[Service]
Type=simple
User=jellyfin
Group=jellyfin
ExecStart=/usr/bin/jellyfin --datadir /home/shared/jellyfin/jellyfin-data --cachedir /home/shared/jellyfin/jellyfin-cache --configdir /home/shared/jellyfin/jellyfin-config --webdir /usr/share/jellyfin/web
WorkingDirectory=/var/lib/jellyfin
Restart=on-failure
RestartSec=5
TimeoutStopSec=20
KillMode=process
Environment="JELLYFIN_DATA_DIR=/home/shared/jellyfin/jellyfin-data"
Environment="JELLYFIN_CACHE_DIR=/home/shared/jellyfin/jellyfin-cache"
Environment="JELLYFIN_CONFIG_DIR=/home/shared/jellyfin/jellyfin-config"
Environment="JELLYFIN_WEB_DIR=/usr/share/jellyfin/web"

[Install]
WantedBy=multi-user.target

# Check group membership
groups jellyfin
groups jellyfin
```

### Check logs
```bash
sudo journalctl -u jellyfin -n 50 --no-pager

```
