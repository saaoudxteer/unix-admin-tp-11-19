# TP 17 — Réseau virtuel de VMs

## Topologie

| VM | Interface | Réseau | Adresse |
|---|---|---|---|
| `nakedeb` | `enp0s8` | `vboxnet0` | `192.168.10.20/24` |
| `rocky1` | `enp0s8` | `vboxnet0` | `192.168.10.30/24` |
| `rocky1` | `enp0s9` | `vboxnet1` | `192.168.20.31/24` |
| `xubuntu` | `enp0s8` | `vboxnet1` | `192.168.20.40/24` |

Chaque VM conserve son premier adaptateur en NAT pour télécharger les paquets. Rocky Linux assure le routage entre les deux réseaux privés.

## Création de `rocky1`

Créer une VM Rocky Linux minimale avec 1 Gio de RAM, 2 vCPU, un disque dynamique de 20 Gio, 16 Mio de mémoire vidéo et le contrôleur graphique VMSVGA. Pendant l'installation, activer l'adaptateur NAT, choisir l'installation minimale, définir le compte `root` et créer un utilisateur standard.

Après le premier démarrage :

```bash
su -
dnf install -y epel-release
dnf install -y gcc dkms make kernel-devel kernel-headers bzip2
usermod -aG wheel <utilisateur>
hostnamectl set-hostname rocky1
systemctl enable --now sshd
reboot
```

Pour les additions invité, insérer leur CD, identifier le périphérique avec `lsblk`, le monter sous `/mnt`, puis exécuter `VBoxLinuxAdditions.run` depuis le point de montage.

Pour administrer la VM avant la création des réseaux privés, ajouter une redirection NAT VirtualBox du port hôte `127.0.0.1:10020` vers le port invité `22`, puis se connecter :

```bash
ssh -p 10020 <utilisateur>@localhost
```

## Préparation côté hôte

Éteindre les trois VMs, adapter leurs noms puis lancer sur l'hôte :

```bash
NAKEDEB_VM=NakeDeb13 \
ROCKY_VM=rocky1 \
XUBUNTU_VM=xubuntu \
./configurer-reseaux-hote.sh
```

Le script crée/configure `vboxnet0` et `vboxnet1`, désactive leur DHCP et attache les cartes aux bonnes VMs.

## Configuration temporaire dans les VMs

Vérifier les noms réels avec `ip -br link`, puis :

```bash
# Dans nakedeb
sudo ./configurer-reseau-live.sh nakedeb

# Dans rocky1
sudo ./configurer-reseau-live.sh rocky1

# Dans xubuntu
sudo ./configurer-reseau-live.sh xubuntu
```

Si une interface porte un autre nom :

```bash
IFACE_LEFT=enp0s8 IFACE_RIGHT=enp0s9 sudo ./configurer-reseau-live.sh rocky1
```

Installer et activer OpenSSH sur Xubuntu/NakeDeb si nécessaire :

```bash
sudo apt install -y openssh-server traceroute
sudo systemctl enable --now ssh
```

Sur Rocky :

```bash
sudo dnf install -y openssh-server traceroute
sudo systemctl enable --now sshd
```

## Vérification du routage

```bash
./verifier-topologie.sh nakedeb
traceroute 192.168.20.40
ssh utilisateur@192.168.20.40
```

Le trajet attendu depuis NakeDeb passe par `192.168.10.30`, puis atteint Xubuntu. Dans l'autre sens, la passerelle est `192.168.20.31`.

Le masquerading n'est pas nécessaire pour router deux sous-réseaux privés connus : des routes correctes et l'autorisation du forwarding suffisent. Il devient utile si les clients doivent sortir par Rocky vers un réseau dont les routeurs ne connaissent pas les réseaux privés.
