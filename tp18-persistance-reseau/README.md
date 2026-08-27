# TP 18 — Persistance réseau, SSH et DNS

Ce TP transforme la configuration temporaire du TP 17 en infrastructure reproductible.

## 1. Réseau persistant

Les trois distributions du laboratoire peuvent être configurées avec NetworkManager :

```bash
sudo ./configurer-reseau-persistant.sh nakedeb
sudo ./configurer-reseau-persistant.sh rocky1
sudo ./configurer-reseau-persistant.sh xubuntu
```

Le script crée des profils dédiés sans modifier l'adaptateur NAT. Sur Rocky, il écrit également `/etc/sysctl.d/90-tp-router.conf` pour conserver l'IP forwarding.

Vérifier après redémarrage :

```bash
nmcli connection show --active
ip -br address
ip route
sysctl net.ipv4.ip_forward   # rocky1 : valeur 1
```

Si NakeDeb n'utilise pas NetworkManager, reproduire la même adresse et la route dans `/etc/network/interfaces.d/enp0s8`, puis redémarrer le service réseau.

## 2. Comptes cohérents et SSH

Sur chacune des trois VMs :

```bash
sudo ./creer-users-partages.sh users.csv
getent passwd alice bruno
id alice
id bruno
```

Les UID/GID `2001` et `2002` sont identiques partout. Pour chaque utilisateur, générer une clé Ed25519 sur chaque VM, puis copier les trois clés publiques vers les trois comptes correspondants :

```bash
sudo passwd alice                       # mot de passe temporaire de laboratoire
sudo -iu alice ssh-keygen -t ed25519
sudo -iu alice ssh-copy-id alice@rocky1.lab.test
sudo -iu alice ssh-copy-id alice@nakedeb.lab.test
sudo -iu alice ssh-copy-id alice@xubuntu.lab.test
```

Répéter depuis chaque VM et pour `bruno`. Vérifier `ssh -o BatchMode=yes ...` avant de verrouiller les mots de passe et de déployer `ssh/99-lab.conf` dans `/etc/ssh/sshd_config.d/`.

```bash
sudo sshd -t
sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh
sudo passwd -l alice
sudo passwd -l bruno
```

Ne jamais copier une clé privée entre les machines : seules les clés publiques rejoignent `authorized_keys`.

## 3. Résolution de noms

Étape locale : ajouter le contenu de `hosts.lab` à `/etc/hosts` sur chaque VM, puis tester `getent hosts rocky1.lab.test`.

Étape DNS :

### Maître Rocky

```bash
sudo dnf install -y bind bind-utils
sudo cp -a /etc/named.conf /etc/named.conf.before-tp18
sudo install -m 0644 dns/rocky1/named.conf /etc/named.conf
sudo install -o root -g named -m 0640 dns/rocky1/db.lab.test /var/named/db.lab.test
sudo named-checkconf
sudo named-checkzone lab.test /var/named/db.lab.test
sudo systemctl enable --now named
```

### Esclave NakeDeb

```bash
sudo apt install -y bind9 dnsutils
sudo install -m 0644 dns/nakedeb/named.conf.local /etc/bind/named.conf.local
sudo named-checkconf
sudo systemctl enable --now bind9
```

Autoriser le service DNS uniquement sur les interfaces internes de Rocky, puis configurer les clients pour interroger d'abord Rocky et ensuite NakeDeb. Contrôles :

```bash
dig @192.168.10.30 rocky1.lab.test
dig @192.168.10.20 xubuntu.lab.test
./verifier-infra.sh
```
