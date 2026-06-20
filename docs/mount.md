# Auto mount example entries

### ntfs
```
/dev/nvme0n1p2 /media/data ntfs defaults,uid=1000,gid=1001,umask=0000,dmask=0000,fmask=0111 0 0
```

### samba share
```
//zbox.local/data /media/zbox cifs credentials=/etc/samba/credentials-data,uid=1000,gid=1000,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0 0 0
//zbox.local/home /media/zbox-home cifs credentials=/etc/samba/credentials-home,uid=1000,gid=1001,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0 0 0
```