# TP 13 — ACL, setuid et setgid

## Laboratoire ACL

Le script `configurer-lab-acl.sh` crée cinq comptes, deux groupes et trois espaces de travail dans `~/tp13-lab` :

| Répertoire | Groupe | Mode initial | Effet |
|---|---|---:|---|
| `albums` | groupe du propriétaire | `0755` | lecture pour tous, écriture réservée au propriétaire |
| `tablatures` | `guitaristes` | `2770` | collaboration du groupe et héritage du GID |
| `paroles` | `chanteurs` | `2750` | lecture/traversée du groupe, aucun droit aux autres |

Les ACL ajoutent ensuite `daisy:r-x` sur `tablatures` et `eric:rwx` sur `paroles`.

```bash
sudo apt install -y acl
sudo ./configurer-lab-acl.sh
getfacl -R ~/tp13-lab
```

Tester avec une nouvelle session pour prendre en compte les groupes :

```bash
sudo -iu alice
cd /home/<proprietaire>/tp13-lab/tablatures
touch essai-alice.txt
```

Les droits sur un répertoire contrôlent la liste (`r`), la traversée (`x`) et la création/suppression/renommage (`w` avec `x`). Les droits du fichier contrôlent ensuite sa lecture et sa modification.

## Recherche des droits spéciaux

Première référence puis comparaison :

```bash
sudo ./scan-nouv-setuid.sh
sudo ./scan-nouv-setuid.sh
```

Le scanner conserve `trace1.txt`, reconstruit `trace2.txt`, trie les deux états et affiche leur différence. Les erreurs des pseudo-systèmes de fichiers sont écartées.

## Démonstrations setuid

Linux ignore le bit setuid sur un script interprété. On peut le constater sans ouvrir de shell privilégié :

```bash
sudo chown root:root demo-setuid-script.sh
sudo chmod 4755 demo-setuid-script.sh
./demo-setuid-script.sh
```

Pour un binaire ELF, le noyau applique le bit et l'EUID devient celui du propriétaire :

```bash
gcc -Wall -Wextra -std=c11 demo-euid.c -o demo-euid
sudo chown root:root demo-euid
sudo chmod 4755 demo-euid
./demo-euid
```

Le programme se limite à afficher les identifiants et quitte immédiatement. Il démontre le risque sans publier de shell root.

Nettoyage :

```bash
sudo rm -f demo-euid
sudo chmod 0755 demo-setuid-script.sh
```

