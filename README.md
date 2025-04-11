# linux-setup

### gnome-extensions
- List existing enabled extensions `gnome-extensions list --enabled`

### setup shared data drive for windows and linux with all users
```bash
sudo mkdir /media/data

# Add entry to /etc/fstab
/dev/nvme0n1p2 /media/data ntfs defaults,uid=1000,gid=1000,umask=0022 0 0

sudo chown -R :shared /media/data
sudo chmod -R 775 /media/data
sudo mount -a
```