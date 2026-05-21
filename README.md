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


## 4) OpenVPN Server Install [install-ovpn-server.sh](https://shriram29.github.io/scripts/install-ovpn-server.sh)
This script installs OpenVPN server and manage clients.

```
curl -fsSLo- https://shriram29.github.io/scripts/install-ovpn-server.sh | bash
```

## 5) Shell Stack Install [install-shell-stack.sh](https://shriram29.github.io/scripts/install-shell-stack.sh)
Sets up a modern terminal stack on Debian/Ubuntu. Installs:
- zsh (set as default shell)
- zsh-autosuggestions + zsh-syntax-highlighting
- starship (prompt)
- btop (resource monitor)
- tmux (terminal multiplexer, with a starter `~/.tmux.conf` — see [tmux-instructions.md](tmux-instructions.md))
- fzf, zoxide, eza, bat, ripgrep, fd (modern CLI tools, aliased over `ls`/`cat`/`cd`)

Run as your **normal user** (not root — it configures your home dir; sudo is used only for apt):
```
wget https://shriram29.github.io/scripts/install-shell-stack.sh
chmod +x install-shell-stack.sh
./install-shell-stack.sh
```
Then start a new session or run `exec zsh`. Tip: install a [Nerd Font](https://www.nerdfonts.com/) in your local terminal so the prompt and `eza` icons render correctly.

