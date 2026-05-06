# 🚀 Guide de Déploiement Production - INPTIC Étudiants

Ce guide vous accompagne pour déployer l'infrastructure INPTIC en production de manière sécurisée.

---

## ⚠️ Checklist Pré-Déploiement

Avant de déployer en production, assurez-vous d'avoir :

- [ ] Un serveur Linux (Ubuntu 20.04+ recommandé)
- [ ] Docker et Docker Compose installés
- [ ] Un nom de domaine configuré (optionnel mais recommandé)
- [ ] Des certificats SSL (Let's Encrypt recommandé)
- [ ] Un compte Gmail avec App Password pour les emails
- [ ] Des backups configurés
- [ ] Un firewall configuré

---

## 🔐 Étape 1 : Sécuriser les Credentials

### 1.1 Copier le Fichier de Configuration Production

```bash
cp .env.production .env
```

### 1.2 Générer des Mots de Passe Sécurisés

Utilisez ces commandes pour générer des mots de passe forts :

```bash
# Générer un mot de passe de 32 caractères
openssl rand -base64 32

# Générer un mot de passe de 64 caractères
openssl rand -base64 64
```

### 1.3 Modifier le Fichier `.env`

Éditez `.env` et changez **TOUS** les mots de passe marqués `CHANGEZ_MOI_` :

```bash
nano .env
```

**Variables CRITIQUES à changer** :

```bash
# PostgreSQL
POSTGRES_PASSWORD=VotreMdpSecure123!@#

# Flask
SECRET_KEY=VotreCleSecrete64CaracteresMinimum!@#$%^&*()

# Grafana
GRAFANA_ADMIN_PASSWORD=GrafanaMdpSecure123!@#
GF_SECURITY_ADMIN_PASSWORD=GrafanaMdpSecure123!@#

# Jenkins
JENKINS_ADMIN_PASSWORD=JenkinsMdpSecure123!@#

# JWT
JWT_SECRET_KEY=VotreCleJWT128CaracteresMinimumPourSecuriteMaximale!@#$%^&*()

# GitHub Token (pour Jenkins CI/CD)
GIT_TOKEN=ghp_VotreTokenGitHub

# PostgreSQL Exporter
DATA_SOURCE_NAME=postgresql://inptic_prod_user:VotreMdpSecure123!@#@db:5432/inptic_prod_db?sslmode=disable
```

### 1.4 Configurer les URLs Externes

Si vous avez un domaine :

```bash
EXTERNAL_URL=https://inptic.votre-domaine.cd
JENKINS_URL=https://inptic.votre-domaine.cd/jenkins
GRAFANA_URL=https://inptic.votre-domaine.cd:3001
PROMETHEUS_URL=https://inptic.votre-domaine.cd:9090
```

---

## 🌐 Étape 2 : Configurer le Serveur

### 2.1 Mettre à Jour le Système

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2 Installer Docker

```bash
# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifier l'installation
docker --version
docker-compose --version
```

### 2.3 Configurer le Firewall

```bash
# Installer UFW
sudo apt install ufw -y

# Autoriser SSH
sudo ufw allow 22/tcp

# Autoriser HTTP et HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Autoriser les ports des services (si accès externe nécessaire)
sudo ufw allow 5000/tcp   # Flask
sudo ufw allow 3001/tcp   # Grafana
sudo ufw allow 8080/tcp   # Jenkins
sudo ufw allow 9090/tcp   # Prometheus
sudo ufw allow 9093/tcp   # Alertmanager

# Activer le firewall
sudo ufw enable

# Vérifier le statut
sudo ufw status
```

---

## 🔒 Étape 3 : Configurer HTTPS (Recommandé)

### 3.1 Installer Certbot (Let's Encrypt)

```bash
sudo apt install certbot -y
```

### 3.2 Obtenir un Certificat SSL

```bash
# Arrêter temporairement les services sur le port 80
sudo certbot certonly --standalone -d votre-domaine.cd

# Les certificats seront dans :
# /etc/letsencrypt/live/votre-domaine.cd/fullchain.pem
# /etc/letsencrypt/live/votre-domaine.cd/privkey.pem
```

### 3.3 Configurer le Renouvellement Automatique

```bash
# Tester le renouvellement
sudo certbot renew --dry-run

# Ajouter un cron job pour le renouvellement automatique
sudo crontab -e

# Ajouter cette ligne :
0 3 * * * certbot renew --quiet --post-hook "docker-compose restart"
```

### 3.4 Configurer Nginx comme Reverse Proxy (Optionnel)

Créez `nginx.conf` :

```nginx
server {
    listen 80;
    server_name votre-domaine.cd;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name votre-domaine.cd;

    ssl_certificate /etc/letsencrypt/live/votre-domaine.cd/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.cd/privkey.pem;

    # Flask App
    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Grafana
    location /grafana/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
    }

    # Jenkins
    location /jenkins/ {
        proxy_pass http://localhost:8080/jenkins/;
        proxy_set_header Host $host;
    }

    # Prometheus
    location /prometheus/ {
        proxy_pass http://localhost:9090/;
        proxy_set_header Host $host;
    }
}
```

---

## 📦 Étape 4 : Déployer l'Application

### 4.1 Cloner le Projet

```bash
cd /opt
sudo git clone https://github.com/Herlymba828/inptic-etudiants.git
cd inptic-etudiants
```

### 4.2 Configurer les Permissions

```bash
sudo chown -R $USER:$USER /opt/inptic-etudiants
chmod 600 .env
```

### 4.3 Démarrer les Services

```bash
# Construire les images
docker-compose build

# Démarrer en mode détaché
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Suivre les logs
docker-compose logs -f
```

### 4.4 Vérifier le Déploiement

```bash
# Tester Flask
curl http://localhost:5000/health

# Tester Grafana
curl http://localhost:3001/api/health

# Tester Prometheus
curl http://localhost:9090/-/healthy

# Voir tous les conteneurs
docker ps
```

---

## 💾 Étape 5 : Configurer les Backups

### 5.1 Créer un Script de Backup

Créez `/opt/inptic-etudiants/scripts/backup.sh` :

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/opt/backups/inptic"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Créer le répertoire de backup
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec postgres-db pg_dump -U inptic_prod_user inptic_prod_db | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# Backup volumes Docker
docker run --rm -v projet-linux_grafana_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana_$DATE.tar.gz -C /data .
docker run --rm -v projet-linux_jenkins_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/jenkins_$DATE.tar.gz -C /data .
docker run --rm -v projet-linux_prometheus_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/prometheus_$DATE.tar.gz -C /data .

# Supprimer les backups de plus de X jours
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup terminé : $DATE"
```

### 5.2 Rendre le Script Exécutable

```bash
chmod +x /opt/inptic-etudiants/scripts/backup.sh
```

### 5.3 Configurer un Cron Job

```bash
crontab -e

# Ajouter cette ligne pour un backup quotidien à 2h du matin
0 2 * * * /opt/inptic-etudiants/scripts/backup.sh >> /var/log/inptic-backup.log 2>&1
```

---

## 📊 Étape 6 : Configurer le Monitoring

### 6.1 Accéder à Grafana

1. Ouvrez https://votre-domaine.cd:3001
2. Connectez-vous avec le mot de passe configuré
3. Vérifiez que le dashboard INPTIC RH affiche les métriques

### 6.2 Configurer les Alertes

1. Dans Grafana, allez dans "Alerting" → "Contact points"
2. Vérifiez que l'email est configuré
3. Testez l'envoi d'une alerte

### 6.3 Vérifier Prometheus

1. Ouvrez https://votre-domaine.cd:9090
2. Allez dans "Status" → "Targets"
3. Vérifiez que toutes les cibles sont "UP"

---

## 🔍 Étape 7 : Tests Post-Déploiement

### 7.1 Tester l'Application

```bash
# Test de santé
curl https://votre-domaine.cd/health

# Test API
curl https://votre-domaine.cd/api/stats

# Test ajout d'étudiant (via l'interface web)
```

### 7.2 Tester les Emails

1. Ajoutez un étudiant via l'interface
2. Vérifiez la réception de l'email
3. Supprimez l'étudiant
4. Vérifiez l'email de suppression

### 7.3 Tester les Backups

```bash
# Exécuter le script de backup manuellement
/opt/inptic-etudiants/scripts/backup.sh

# Vérifier les fichiers de backup
ls -lh /opt/backups/inptic/
```

---

## 🚨 Étape 8 : Surveillance et Maintenance

### 8.1 Surveiller les Logs

```bash
# Logs en temps réel
docker-compose logs -f

# Logs d'un service spécifique
docker logs flask-app -f

# Logs système
tail -f /var/log/syslog
```

### 8.2 Surveiller les Ressources

```bash
# Utilisation des ressources Docker
docker stats

# Espace disque
df -h

# Mémoire
free -h

# Processus
top
```

### 8.3 Mises à Jour

```bash
# Mettre à jour le code
cd /opt/inptic-etudiants
git pull

# Reconstruire et redémarrer
docker-compose build
docker-compose up -d

# Vérifier
docker-compose ps
```

---

## 🔧 Commandes Utiles en Production

### Redémarrer les Services

```bash
# Redémarrer tous les services
docker-compose restart

# Redémarrer un service spécifique
docker-compose restart app

# Arrêter tous les services
docker-compose down

# Démarrer tous les services
docker-compose up -d
```

### Voir les Logs

```bash
# Tous les logs
docker-compose logs

# Logs d'un service
docker-compose logs app

# Suivre les logs en temps réel
docker-compose logs -f app

# Dernières 100 lignes
docker-compose logs --tail=100 app
```

### Nettoyer Docker

```bash
# Supprimer les conteneurs arrêtés
docker container prune -f

# Supprimer les images inutilisées
docker image prune -a -f

# Supprimer les volumes inutilisés
docker volume prune -f

# Nettoyer tout
docker system prune -a --volumes -f
```

---

## 🆘 Dépannage Production

### Problème : Service ne Démarre Pas

```bash
# Vérifier les logs
docker-compose logs <service>

# Vérifier la configuration
docker-compose config

# Redémarrer le service
docker-compose restart <service>
```

### Problème : Base de Données Corrompue

```bash
# Restaurer depuis un backup
gunzip < /opt/backups/inptic/postgres_YYYYMMDD_HHMMSS.sql.gz | docker exec -i postgres-db psql -U inptic_prod_user -d inptic_prod_db
```

### Problème : Espace Disque Plein

```bash
# Trouver les gros fichiers
du -sh /* | sort -h

# Nettoyer les logs Docker
docker system prune -a --volumes

# Nettoyer les anciens backups
find /opt/backups/inptic -name "*.gz" -mtime +30 -delete
```

---

## 📞 Support Production

### Contacts d'Urgence

- **Admin Principal** : herlymba828@gmail.com
- **Compte Technique** : ingridboussoyi@gmail.com

### Logs Importants

- **Application** : `docker logs flask-app`
- **Base de données** : `docker logs postgres-db`
- **Système** : `/var/log/syslog`
- **Backups** : `/var/log/inptic-backup.log`

### Monitoring

- **Grafana** : https://votre-domaine.cd:3001
- **Prometheus** : https://votre-domaine.cd:9090
- **Alertmanager** : https://votre-domaine.cd:9093

---

## ✅ Checklist Post-Déploiement

- [ ] Tous les services sont en cours d'exécution
- [ ] Tous les mots de passe ont été changés
- [ ] HTTPS est configuré et fonctionne
- [ ] Les backups automatiques sont configurés
- [ ] Le firewall est activé et configuré
- [ ] Les alertes email fonctionnent
- [ ] Le monitoring Grafana affiche les métriques
- [ ] Les logs sont accessibles et surveillés
- [ ] La documentation est à jour
- [ ] L'équipe a accès aux credentials

---

**🎉 Félicitations ! Votre infrastructure INPTIC est maintenant en production !**

*Dernière mise à jour : 6 mai 2026*
