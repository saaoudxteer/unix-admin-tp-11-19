# TP 12 — Création d'utilisateurs

> À exécuter uniquement dans la VM de laboratoire. Un mot de passe vide est volontairement demandé par l'exercice et ne doit jamais être utilisé sur une machine réelle.

## Utilisateurs et groupes

Après avoir créé `samob` puis activé son rôle administrateur, comparer les groupes avant et après :

```bash
id samob
getent group | grep -w samob
```

Sur Xubuntu, les groupes ajoutés incluent généralement `sudo` et plusieurs groupes donnant accès aux périphériques ou services (`adm`, `cdrom`, `dip`, `plugdev`, `lpadmin`, `sambashare`). La sortie locale fait foi car la liste varie selon la version.

Audits demandés :

```bash
sudo awk -F: '$2 == "" {print $1}' /etc/shadow
awk -F: '$3 == $4 {printf "%-20s uid=%s gid=%s\n", $1, $3, $4}' /etc/passwd
```

Le fichier `/etc/passwd` contient habituellement `x` dans son deuxième champ ; l'information réelle sur le mot de passe se trouve dans `/etc/shadow`.

## Comprendre `useradd`

```bash
sudo useradd -c "Laurent Outang" -m -p '' outang
```

- `-c` définit le champ descriptif GECOS ;
- `-m` crée le répertoire personnel ;
- `-p ''` place une valeur vide dans le champ du mot de passe ;
- sans `-s`, le shell vient de la configuration par défaut de `useradd`.

Pour corriger le shell :

```bash
sudo usermod -s /bin/bash outang
# À la création : useradd -s /bin/bash ...
```

## Script fourni

Création :

```bash
sudo ./creer_users.sh -c users.txt
```

Suppression des mêmes identités et de leurs répertoires :

```bash
sudo ./creer_users.sh -d users.txt
```

Le login est composé du nom de famille normalisé et de la première lettre du premier prénom. Un suffixe numérique évite les collisions. Une identité déjà existante n'est pas recréée.

## Vérification

```bash
./lister-comptes.sh
getent passwd deufj
sudo getent shadow deufj
```

