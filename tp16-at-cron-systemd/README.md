# TP 16 — `at`, `cron` et `systemd`

## Tâche ponctuelle avec `at`

```bash
sudo apt install -y at mailutils
sudo systemctl enable --now atd
echo "$PWD/compresse-gif.sh $HOME" | at now + 2 minutes
atq
```

Après exécution, `atq` redevient vide, les GIF sont compressés et la sortie éventuelle peut être lue avec `mail`. Pour annuler avant exécution : `atrm <numero>`.

## Tâche répétée avec `cron`

Installer le script :

```bash
sudo install -o root -g root -m 0755 nettoyage.sh /usr/local/sbin/nettoyage.sh
sudo crontab -e
```

Ajouter la ligne de `cron-nettoyage.example`. Le rapport se trouve dans `/tmp/bilan-nettoyage.txt`. Après vérification, commenter la ligne pour désactiver la tâche.

## Service ROT13

```bash
sudo apt install -y netcat-openbsd
sudo install -o root -g root -m 0755 serveur-rot13.sh /usr/local/bin/serveur-rot13.sh
sudo install -o root -g root -m 0644 myrot13.service /etc/systemd/system/myrot13.service
sudo systemctl daemon-reload
sudo systemctl enable --now myrot13.service
systemctl status myrot13.service
nc localhost 13000
```

Le journal est disponible avec :

```bash
journalctl -u myrot13.service -f
```

Pour vérifier le redémarrage automatique, noter le PID, tuer le processus enfant puis relire le statut. `systemctl mask` n'arrête pas un service déjà actif, mais empêche un nouveau démarrage après l'arrêt. `systemctl unmask myrot13.service` le débloque.

