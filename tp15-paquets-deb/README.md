# TP 15 — Paquets Debian et création d'un `.deb`

## Inventaire des paquets

Deux comptages équivalents :

```bash
dpkg -l | awk '$1 == "ii" {count++} END {print count}'
dpkg --get-selections | awk '$2 == "install" {count++} END {print count}'
```

Créer les états avant/après puis afficher uniquement les ajouts :

```bash
./lister-paquets.sh liste1.txt
# Ajouter le PPA supporté, apt update, installer le paquet choisi.
./lister-paquets.sh liste2.txt
./comparer-paquets.sh liste1.txt liste2.txt
```

Avant d'ajouter un PPA, vérifier que le nom de version retourné par `lsb_release -sc` existe dans le dépôt. Ne pas forcer un PPA prévu pour une autre version d'Ubuntu.

```bash
lsb_release -sc
sudo apt-add-repository ppa:umang/indicator-stickynotes
sudo apt update
sudo apt install indicator-stickynotes
```

Si cette version d'Ubuntu n'est plus publiée par ce PPA, utiliser le remplacement indiqué dans l'énoncé (par exemple le PPA Mozilla et `firefox-esr`) et noter clairement cette adaptation dans les preuves.

Gestion du gel :

```bash
sudo apt-mark hold indicator-stickynotes
apt-mark showhold
dpkg --get-selections | grep indicator-stickynotes
sudo apt-mark unhold indicator-stickynotes
```

Après l'exercice, supprimer le PPA avec `apt-add-repository --remove`, exécuter `apt update`, puis vérifier `apt policy`.

## Construction manuelle

`gen-demo-deb.sh` reproduit la structure Debian bas niveau :

1. compilation du binaire ;
2. création de `data.tar.xz` ;
3. création de `control.tar.xz` avec `control`, `md5sums` et `postinst` ;
4. assemblage avec `ar` après `debian-binary`.

```bash
./gen-demo-deb.sh .
ar t euid-demo_1.0_$(dpkg --print-architecture).deb
dpkg-deb --info euid-demo_1.0_$(dpkg --print-architecture).deb
sudo dpkg -i euid-demo_1.0_$(dpkg --print-architecture).deb
/usr/bin/euid-demo
sudo apt remove euid-demo
```

Le paquet place le bit setuid sur un programme **inoffensif** qui affiche seulement UID/EUID. Cela démontre pourquoi un paquet non fiable est dangereux sans installer de shell privilégié.

Pour observer la protection d'un paquet essentiel dans la VM uniquement :

```bash
./gen-demo-deb.sh . --essential
sudo dpkg -i euid-demo_1.0_$(dpkg --print-architecture).deb
sudo apt remove euid-demo             # refus attendu
sudo dpkg --remove --force-remove-essential euid-demo
```

L'option de forçage confirme que `Essential: yes` est une protection contre une suppression accidentelle, pas une impossibilité technique.
