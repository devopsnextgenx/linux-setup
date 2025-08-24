### install and setup zbox mount
```
sudo apt install cifs-utils -y
sudo mkdir -p /media/zbox
sudo cat > /etc/samba/credentials << EOF
username=admn
password=p@ssw0rd
EOF
sudo chmod 600 /etc/samba/credentials

echo "//zbox.local/data /media/zbox cifs credentials=/etc/samba/credentials,uid=1000,gid=1000,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0 0 0" >> /etc/fstab
sudo mount -a

```