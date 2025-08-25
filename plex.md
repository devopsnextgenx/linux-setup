# Update plexmediaserver library location
```bash
sudo systemctl stop plexmediaserver
sudo mv /var/lib/plexmediaserver/Library /var/lib/plexmediaserver/Library.bak
sudo ln -s /home/shared/plex/Library /var/lib/plexmediaserver/Library
sudo chown -h plex:plex /var/lib/plexmediaserver/Library
sudo systemctl restart plexmediaserver
sudo systemctl start plexmediaserver
```
