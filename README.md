# Dump of useful scripts 

## 1) Give me ssh access- [lemmein.sh](https://shriram29.github.io/scripts/lemmein.sh)
```
curl -fsSLo- https://shriram29.github.io/scripts/lemmein.sh | bash
```

## 2) Wordpress Install [install-wp-ssl.sh](https://shriram29.github.io/scripts/install-wp-ssl.sh)
Installs the following:
- Wordpress
- Apache
- php8.1
- mysql
- Certbot SSL 

```
wget https://shriram29.github.io/scripts/install-wp-ssl.sh 
chmod +x install-wp-ssl.sh
```
```
sudo ./install-wp-ssl.sh <DOMAIN> <email>
```

## 3) Servarr Stack Install [install-servarr-stack.sh](https://shriram29.github.io/scripts/install-servarr-stack.sh)
Installs the following:
- jackett
- sonarr
- lidarr
- radarr
- readarr
- whisparr
- prowlarr
- bazarr

```
sudo sh -c "$(wget -qO- https://shriram29.github.io/scripts/install-servarr-stack.sh)" 
```


## 3) OpenVPN Server Install [install-ovpn-server.sh](https://shriram29.github.io/scripts/install-ovpn-server.sh)
This script installs OpenVPN server and manage clients.

```
curl -fsSLo- https://shriram29.github.io/scripts/install-ovpn-server.sh | bash
```

