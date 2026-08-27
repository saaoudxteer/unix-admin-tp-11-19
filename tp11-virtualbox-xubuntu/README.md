# TP 11 — VM Xubuntu sur VirtualBox

## Objectifs

Installer une VM Xubuntu LTS, dimensionner ses ressources, installer les additions invité, partager un dossier avec l'hôte et tester un périphérique USB.

## Configuration retenue

| Élément | Valeur |
|---|---|
| Nom | `xubuntu` |
| Type | Linux / Ubuntu 64 bits |
| CPU | 2 vCPU |
| RAM | 2 Gio |
| Disque | VDI dynamique, 20 Gio |
| Vidéo | 128 Mio, accélération 3D si disponible |
| Réseau initial | NAT |

Prendre la dernière image Xubuntu LTS compatible avec la machine hôte. Après l'installation, mettre le système à jour :

```bash
sudo apt update
sudo apt full-upgrade -y
```

## Additions invité

```bash
sudo apt install -y build-essential dkms "linux-headers-$(uname -r)"
```

Insérer ensuite l'image des additions depuis le menu VirtualBox, ouvrir un terminal dans le CD et lancer :

```bash
sudo ./VBoxLinuxAdditions.run
sudo reboot
```

## Dossier partagé

Créer côté hôte `PartageXUbu`, l'ajouter comme dossier partagé permanent et automatique, puis autoriser l'utilisateur invité :

```bash
sudo usermod -aG vboxsf "$USER"
```

Une déconnexion/reconnexion est nécessaire. Vérifier ensuite :

```bash
id
mount | grep vboxsf
```

## USB

Sur un hôte Linux, ajouter l'utilisateur hôte au groupe `vboxusers`, se reconnecter, puis sélectionner la clé depuis **Périphériques > USB**. Toujours quitter le répertoire monté avant l'éjection.

## Preuves attendues

Exécuter le script fourni dans la VM :

```bash
./collecte-infos-vm.sh
```

Le rapport doit confirmer la distribution, les CPU, la RAM, le disque, le réseau, les modules VirtualBox et le groupe `vboxsf`.

