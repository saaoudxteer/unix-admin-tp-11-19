# TP 14 — NakeDeb et LVM

## Architecture du stockage

La VM `NakeDeb13` utilise 2 vCPU, 2 Gio de RAM et deux VDI dynamiques de 20 Gio.

| Disque | Partition | Usage |
|---|---|---|
| `/dev/sda` | `/dev/sda1`, 1 Gio | `/boot`, ext4, amorçable |
| `/dev/sda` | `/dev/sda5`, reste du disque | PV du groupe `NDebVG` |
| `/dev/sdb` | `/dev/sdb1`, disque entier | second PV, ajouté après installation |

Dans `NDebVG` :

- `Root` : 12 Gio, ext4, monté sur `/` ;
- `Home` : tout l'espace restant, ext4, monté sur `/home`.

## Création initiale

Après le partitionnement avec `fdisk` :

```bash
sudo apt update && sudo apt install -y lvm2
sudo pvcreate /dev/sda5
sudo vgcreate NDebVG /dev/sda5
sudo lvcreate -L 12G -n Root NDebVG
sudo lvcreate -l 100%FREE -n Home NDebVG
sudo pvs
sudo vgs
sudo lvs
```

Le partitionnement de l'installateur associe ensuite `/dev/NDebVG/Root` à `/`, `/dev/NDebVG/Home` à `/home` et `/dev/sda1` à `/boot`.

Après installation, installer `build-essential`, `dkms` et les en-têtes du noyau. NakeDeb ne montant pas toujours le CD automatiquement, l'identifier avec `lsblk`, créer un point de montage, lancer `mount`, puis exécuter `VBoxLinuxAdditions.run`. Activer ensuite le presse-papiers bidirectionnel et redémarrer.

## Ajout du second disque

Le script fourni affiche le plan sans modifier le système :

```bash
./etendre-home.sh --pv /dev/sdb1
```

Après vérification de `lsblk`, appliquer explicitement :

```bash
sudo ./etendre-home.sh --pv /dev/sdb1 --apply
sudo ./verifier-lvm.sh
```

## Transférer 2 Gio de `Home` vers `Root`

Un système ext4 peut grandir en ligne, mais ne peut pas être réduit lorsqu'il est monté. La procédure sûre est : sauvegarde vérifiée, démarrage sur un environnement live, désactivation des processus utilisant `/home`, démontage, `e2fsck`, réduction du système de fichiers puis du LV, et enfin extension de `Root`.

```bash
sudo umount /home
sudo e2fsck -f /dev/NDebVG/Home
sudo lvreduce --resizefs -L -2G /dev/NDebVG/Home
sudo lvextend --resizefs -L +2G /dev/NDebVG/Root
```

`lvreduce` peut détruire les données si la taille calculée est incorrecte : ne jamais l'automatiser sans sauvegarde et contrôle de l'espace réellement utilisé.
