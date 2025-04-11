# linux-setup

### gnome-extensions
- List existing enabled extensions `gnome-extensions list --enabled`

### setup shared data drive for windows and linux with all users
```bash
sudo mkdir /mnt/data

# Add entry to /etc/fstab
/dev/nvme0n1p2 /mnt/data ntfs defaults,uid=1000,gid=1000,umask=0022 0 0

sudo chown -R :shared /mnt/data
sudo chmod -R 775 /mnt/data
sudo mount -a
```