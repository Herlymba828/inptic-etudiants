# 🚀 Installation sur CentOS Stream 10 - INPTIC Étudiants

Guide complet d'installation de l'infrastructure INPTIC sur CentOS Stream 10.

---

## 📋 Prérequis

- Serveur CentOS Stream 10 (minimum 4 GB RAM, 20 GB disque)
- Accès root ou sudo
- Connexion Internet
- (Optionnel) Nom de domaine configuré

---

## 🔧 Étape 1 : Préparation du Système

### 1.1 Mettre à Jour le Système

```bash
# Se connecter en root
sudo su -

# Mettre à jour le système
dnf update -y

# Installer les outils de base
dnf install -y git curl wget nano vim net-tools
```

### 1.2 Configurer le Hostname (Optionnel)

```bash
# Définir le hostname
hostnamectl set-hostname inptic-prod.votre-domaine.cd

# Vérifier
hostnamectl
```

### 1.3 Désactiver SELinux (Temporaire pour Docker)

```bash
# Désactiver temporairement
setenforce 0

# Désactiver de manière permanente
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Vérifier
getenforce
```

---

## 🐳 Étape 2 : Installation de Docker

### 2.1 Installer les Dépendances

```bash
# Installer les dépendances
dnf install -y dnf-plugins-core

# Ajouter le dépôt Docker
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### 2.2 Installer Docker Engine

```bash
# Installer Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrer Docker
systemctl start docker

# Activer au démarrage
systemctl enable docker

# Vérifier l'installation
docker --version
docker run hello-world
```

### 2.3 Configurer Docker (Optionnel)

```bash
# Créer le groupe docker si nécessaire
groupadd docker

# Ajouter votre utilisateur au groupe docker
usermod -aG docker $USER

# Appliquer les changements (ou se reconnecter)
newgrp docker

# Tester sans sudo
docker ps
```

---

## 🔧 Étape 3 : Installation de Docker Compose

### 3.1 Installer Docker Compose

```bash
# Docker Compose est déjà installé avec docker-compose-plugin
# Vérifier la version
docker compose version

# Si besoin d'installer manuellement
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Vérifier
docker-compose --version
```

---

## 🔥 Étape 4 : Configuration du Firewall

### 4.1 Installer et Configurer Firewalld

```bash
# Installer firewalld
dnf install -y firewalld

# Démarrer firewalld
systemctl start firewalld
systemctl enable firewalld

# Vérifier le statut
systemctl status firewalld
```

### 4.2 Ouvrir les Ports Nécessaires

```bash
# SSH (si pas déjà ouvert)
firewall-cmd --permanent --add-service=ssh

# HTTP et HTTPS
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Flask App
firewall-cmd --permanent --add-port=5000/tcp

# Grafana
firewall-cmd --permanent --add-port=3001/tcp

# Jenkins
firewall-cmd --permanent --add-port=8080/tcp

# Prometheus
firewall-cmd --permanent --add-port=9090/tcp

# Alertmanager
firewall-cmd --permanent --add-port=9093/tcp

# Recharger le firewall
firewall-cmd --reload

# Vérifier les règles
firewall-cmd --list-all
```

---

## 🔐 Étape 5 : Configuration SSL/TLS (Optionnel mais Recommandé)

### 5.1 Installer Certbot

```bash
# Installer EPEL repository
dnf install -y epel-release

# Installer Certbot
dnf install -y certbot

# Vérifier
certbot --version
```

### 5.2 Obtenir un Certificat SSL

```bash
# Arrêter temporairement les services sur le port 80 si nécessaire
systemctl stop httpd nginx 2>/dev/null

# Obtenir le certificat
certbot certonly --standalone -d votre-domaine.cd -d www.votre-domaine.cd

# Les certificats seront dans :
# /etc/letsencrypt/live/votre-domaine.cd/fullchain.pem
# /etc/letsencrypt/live/votre-domaine.cd/privkey.pem
```

### 5.3 Configurer le Renouvellement Automatique

```bash
# Tester le renouvellement
certbot renew --dry-run

# Ajouter un cron job
crontab -e

# Ajouter cette ligne :
0 3 * * * certbot renew --quiet --post-hook "cd /opt/inptic-etudiants && docker-compose restart"
```

---

## 📦 Étape 6 : Déploiement de l'Application

### 6.1 Créer le Répertoire de Travail

```bash
# Créer le répertoire
mkdir -p /opt/inptic-etudiants
cd /opt/inptic-etudiants
```

### 6.2 Cloner le Projet

```bash
# Cloner depuis GitHub
git clone https://github.com/Herlymba828/inptic-etudiants.git .

# Vérifier les fichiers
ls -la
```

### 6.3 Configurer les Variables d'Environnement

```bash
# Copier le template de production
cp .env.production .env

# Éditer le fichier
nano .env
```

**Variables CRITIQUES à modifier** :

```bash
# PostgreSQL
POSTGRES_USER=inptic_prod_user
POSTGRES_PASSWORD=VotreMdpPostgresSecure2024!@#
POSTGRES_DB=inptic_prod_db

# Flask
SECRET_KEY=$(openssl rand -base64 32)

# Grafana
GRAFANA_ADMIN_PASSWORD=VotreMdpGrafanaSecure2024!@#
GF_SECURITY_ADMIN_PASSWORD=VotreMdpGrafanaSecure2024!@#

# Jenkins
JENKINS_ADMIN_PASSWORD=VotreMdpJenkinsSecure2024!@#

# JWT
JWT_SECRET_KEY=$(openssl rand -base64 64)

# Email (déjà configuré)
SMTP_USER=ingridboussoyi@gmail.com
SMTP_PASSWORD=obbpuwbbcducpuqv
NOTIFICATION_EMAIL=herlymba828@gmail.com

# URLs (si vous avez un domaine)
EXTERNAL_URL=https://votre-domaine.cd
JENKINS_URL=https://votre-domaine.cd/jenkins
GRAFANA_URL=https://votre-domaine.cd:3001
PROMETHEUS_URL=https://votre-domaine.cd:9090

# PostgreSQL Exporter (mettre le même mot de passe que POSTGRES_PASSWORD)
DATA_SOURCE_NAME=postgresql://inptic_prod_user:VotreMdpPostgresSecure2024!@#@db:5432/inptic_prod_db?sslmode=disable
```

### 6.4 Sécuriser le Fichier .env

```bash
# Restreindre les permissions
chmod 600 .env

# Vérifier
ls -l .env
```

### 6.5 Générer des Mots de Passe Forts

```bash
# Générer un mot de passe de 32 caractères
echo "SECRET_KEY=$(openssl rand -base64 32)"

# Générer un mot de passe de 64 caractères
echo "JWT_SECRET_KEY=$(openssl rand -base64 64)"

# Générer un mot de passe aléatoire
openssl rand -base64 24
```

---

## 🚀 Étape 7 : Démarrage des Services

### 7.1 Construire les Images

```bash
cd /opt/inptic-etudiants

# Construire les images Docker
docker-compose build

# Cela peut prendre quelques minutes...
```

### 7.2 Démarrer les Services

```bash
# Démarrer en mode détaché
docker-compose up -d

# Vérifier l'état
docker-compose ps
```

### 7.3 Vérifier les Logs

```bash
# Voir tous les logs
docker-compose logs

# Suivre les logs en temps réel
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f app
docker-compose logs -f grafana
docker-compose logs -f postgres-db
```

---

## ✅ Étape 8 : Vérification du Déploiement

### 8.1 Vérifier les Conteneurs

```bash
# Lister les conteneurs
docker ps

# Vous devriez voir 7 conteneurs :
# - flask-app
# - postgres-db
# - prometheus
# - grafana
# - jenkins
# - alertmanager
# - postgres-exporter
```

### 8.2 Tester les Services

```bash
# Tester Flask
curl http://localhost:5000/health

# Tester Grafana
curl http://localhost:3001/api/health

# Tester Prometheus
curl http://localhost:9090/-/healthy

# Tester Alertmanager
curl http://localhost:9093/-/healthy

# Tester Jenkins
curl http://localhost:8080/jenkins/login
```

### 8.3 Vérifier depuis un Navigateur

Depuis votre machine locale, ouvrez :

```
http://IP_DU_SERVEUR:5000          # Flask App
http://IP_DU_SERVEUR:3001          # Grafana (admin/VotreMdp)
http://IP_DU_SERVEUR:8080/jenkins  # Jenkins (admin/VotreMdp)
http://IP_DU_SERVEUR:9090          # Prometheus
http://IP_DU_SERVEUR:9093          # Alertmanager
```

---

## 💾 Étape 9 : Configuration des Backups

### 9.1 Créer le Script de Backup

```bash
# Créer le répertoire de backups
mkdir -p /opt/backups/inptic

# Créer le script
nano /opt/inptic-etudiants/scripts/backup.sh
```

Contenu du script :

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/opt/backups/inptic"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
LOG_FILE="/var/log/inptic-backup.log"

# Fonction de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "=== Début du backup ==="

# Créer le répertoire de backup
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
log "Backup PostgreSQL..."
docker exec postgres-db pg_dump -U inptic_prod_user inptic_prod_db | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz
if [ $? -eq 0 ]; then
    log "✅ Backup PostgreSQL réussi"
else
    log "❌ Erreur backup PostgreSQL"
fi

# Backup Grafana
log "Backup Grafana..."
docker run --rm -v projet-linux_grafana_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana_$DATE.tar.gz -C /data .
if [ $? -eq 0 ]; then
    log "✅ Backup Grafana réussi"
else
    log "❌ Erreur backup Grafana"
fi

# Backup Jenkins
log "Backup Jenkins..."
docker run --rm -v projet-linux_jenkins_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/jenkins_$DATE.tar.gz -C /data .
if [ $? -eq 0 ]; then
    log "✅ Backup Jenkins réussi"
else
    log "❌ Erreur backup Jenkins"
fi

# Backup Prometheus
log "Backup Prometheus..."
docker run --rm -v projet-linux_prometheus_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/prometheus_$DATE.tar.gz -C /data .
if [ $? -eq 0 ]; then
    log "✅ Backup Prometheus réussi"
else
    log "❌ Erreur backup Prometheus"
fi

# Supprimer les backups de plus de X jours
log "Nettoyage des anciens backups..."
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

log "=== Backup terminé ==="
log "Espace disque utilisé : $(du -sh $BACKUP_DIR | cut -f1)"
```

### 9.2 Rendre le Script Exécutable

```bash
chmod +x /opt/inptic-etudiants/scripts/backup.sh

# Tester le script
/opt/inptic-etudiants/scripts/backup.sh

# Vérifier les backups
ls -lh /opt/backups/inptic/
```

### 9.3 Configurer le Cron Job

```bash
# Éditer le crontab
crontab -e

# Ajouter cette ligne pour un backup quotidien à 2h du matin
0 2 * * * /opt/inptic-etudiants/scripts/backup.sh

# Vérifier le crontab
crontab -l
```

---

## 📊 Étape 10 : Configuration du Monitoring

### 10.1 Accéder à Grafana

```bash
# Obtenir l'IP du serveur
ip addr show | grep inet

# Ouvrir dans le navigateur
http://IP_DU_SERVEUR:3001
```

**Connexion** :
- Username : `admin`
- Password : Celui configuré dans `.env`

### 10.2 Vérifier le Dashboard

1. Cliquez sur "Dashboards" dans le menu
2. Sélectionnez "INPTIC RH"
3. Vérifiez que les métriques s'affichent

### 10.3 Configurer les Alertes

1. Allez dans "Alerting" → "Contact points"
2. Vérifiez que l'email `herlymba828@gmail.com` est configuré
3. Testez l'envoi d'une alerte

---

## 🔍 Étape 11 : Tests Post-Déploiement

### 11.1 Tester l'Application

```bash
# Test de santé
curl http://localhost:5000/health

# Test API stats
curl http://localhost:5000/api/stats

# Test métriques
curl http://localhost:5000/metrics
```

### 11.2 Tester l'Ajout d'un Étudiant

1. Ouvrez http://IP_DU_SERVEUR:5000
2. Cliquez sur "Ajouter un étudiant"
3. Remplissez le formulaire
4. Vérifiez la réception de l'email sur `herlymba828@gmail.com`

### 11.3 Vérifier les Logs

```bash
# Logs Flask
docker logs flask-app --tail 50

# Logs PostgreSQL
docker logs postgres-db --tail 50

# Logs Grafana
docker logs grafana --tail 50
```

---

## 🔧 Étape 12 : Configuration Système

### 12.1 Configurer le Démarrage Automatique

```bash
# Créer un service systemd
nano /etc/systemd/system/inptic.service
```

Contenu :

```ini
[Unit]
Description=INPTIC Étudiants Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/inptic-etudiants
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

Activer le service :

```bash
# Recharger systemd
systemctl daemon-reload

# Activer le service
systemctl enable inptic.service

# Tester
systemctl start inptic.service
systemctl status inptic.service
```

### 12.2 Configurer la Rotation des Logs

```bash
# Créer la configuration logrotate
nano /etc/logrotate.d/inptic
```

Contenu :

```
/var/log/inptic-backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
```

---

## 🚨 Dépannage CentOS

### Problème : Docker ne Démarre Pas

```bash
# Vérifier le statut
systemctl status docker

# Voir les logs
journalctl -u docker -n 50

# Redémarrer Docker
systemctl restart docker
```

### Problème : Firewall Bloque les Connexions

```bash
# Vérifier les règles
firewall-cmd --list-all

# Désactiver temporairement pour tester
systemctl stop firewalld

# Si ça fonctionne, ajouter les bonnes règles
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload
```

### Problème : SELinux Bloque Docker

```bash
# Vérifier le statut SELinux
getenforce

# Désactiver temporairement
setenforce 0

# Désactiver de manière permanente
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
```

### Problème : Espace Disque Insuffisant

```bash
# Vérifier l'espace disque
df -h

# Nettoyer Docker
docker system prune -a --volumes -f

# Nettoyer les anciens backups
find /opt/backups/inptic -name "*.gz" -mtime +7 -delete
```

---

## 📊 Surveillance et Maintenance

### Commandes Utiles

```bash
# Voir l'état des services
docker-compose ps

# Redémarrer tous les services
docker-compose restart

# Voir les ressources utilisées
docker stats

# Voir l'espace disque
df -h

# Voir la mémoire
free -h

# Voir les processus
top
```

### Logs Système

```bash
# Logs Docker
journalctl -u docker -f

# Logs système
tail -f /var/log/messages

# Logs backups
tail -f /var/log/inptic-backup.log
```

---

## ✅ Checklist Finale

- [ ] CentOS Stream 10 à jour
- [ ] Docker et Docker Compose installés
- [ ] Firewall configuré
- [ ] SSL/TLS configuré (optionnel)
- [ ] Projet cloné dans `/opt/inptic-etudiants`
- [ ] Fichier `.env` configuré avec mots de passe forts
- [ ] Tous les services démarrés (`docker-compose ps`)
- [ ] Tests de connexion réussis
- [ ] Backups automatiques configurés
- [ ] Service systemd activé
- [ ] Monitoring Grafana fonctionnel
- [ ] Emails de notification testés

---

## 📞 Support

**En cas de problème** :
- Consultez les logs : `docker-compose logs -f`
- Vérifiez le firewall : `firewall-cmd --list-all`
- Vérifiez SELinux : `getenforce`
- Contactez : herlymba828@gmail.com

---

**🎉 Félicitations ! INPTIC Étudiants est maintenant déployé sur CentOS Stream 10 !**

*Guide créé le 6 mai 2026*
