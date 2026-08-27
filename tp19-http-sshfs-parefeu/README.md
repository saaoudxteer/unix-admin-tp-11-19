# TP 19 — Apache, SSHFS, firewalld et fail2ban

## 1. Apache sur Rocky

Copier ce dossier dans `rocky1`, puis préciser les utilisateurs à publier :

```bash
sudo ./installer-httpd.sh alice bruno
curl http://rocky1.lab.test/~alice/
```

Le script installe Apache, crée `/space/users/<user>/public_html`, déploie l'alias `~user`, applique les contextes SELinux et valide la configuration avant le démarrage.

Observer les journaux pendant les tests :

```bash
sudo journalctl -u httpd -f
sudo tail -f /var/log/httpd/access_log /var/log/httpd/error_log
```

## 2. Montage SSHFS depuis Xubuntu

Après validation de l'authentification SSH par clé :

```bash
sudo apt install -y sshfs
install -d "$HOME/.local/bin"
install -m 0755 sshfs/mount-rocky1.sh "$HOME/.local/bin/"
install -m 0755 sshfs/unmount-rocky1.sh "$HOME/.local/bin/"
```

Ajouter à `~/.profile` :

```bash
"$HOME/.local/bin/mount-rocky1.sh"
```

Et à `~/.bash_logout` :

```bash
"$HOME/.local/bin/unmount-rocky1.sh"
```

Le journal utilisateur est écrit dans `~/.local/state/tp19-sshfs.log`. Le montage n'empêche pas une ouverture de session lorsque Rocky est indisponible.

## 3. Pare-feu Rocky

Le script crée deux zones :

- `tp-internal` pour `enp0s8` et `enp0s9` ;
- `tp-public` pour `enp0s3`, avec uniquement les services `ssh` (22/TCP) et `http` (80/TCP).

```bash
PUBLIC_IF=enp0s3 INTERNAL_IF_1=enp0s8 INTERNAL_IF_2=enp0s9 \
  sudo ./firewall/configurer-firewalld.sh
```

Les services firewalld ouvrent IPv4 et IPv6. La zone publique personnalisée ne contient pas les services ajoutés par défaut à certaines distributions.

Fail2ban :

```bash
sudo dnf install -y epel-release
sudo dnf install -y fail2ban fail2ban-firewalld
sudo install -m 0644 firewall/jail.local /etc/fail2ban/jail.local
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

## Simulation d'une machine extérieure

Créer un troisième réseau VirtualBox distinct, par exemple un **réseau interne** `outside-lab`, avec `10.90.0.0/24` et `fd00:90::/64`. Ajouter une carte à Rocky (`10.90.0.1`) et une carte à une VM de test (`10.90.0.2`). Comme ce réseau n'est ni `vboxnet0` ni `vboxnet1`, il représente l'extérieur.

Depuis la VM de test :

```bash
nc -vz 10.90.0.1 22       # doit réussir
nc -vz 10.90.0.1 80       # doit réussir
nc -vz 10.90.0.1 53       # doit échouer
curl http://10.90.0.1/
```

Répéter avec l'adresse IPv6 et vérifier l'état global avec `./verifier-services.sh`.

