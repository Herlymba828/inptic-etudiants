# Guide de Déploiement sur VM

## Prérequis sur la VM

Assurez-vous que votre VM dispose de :
- Docker (version 20.10+)
- Docker Compose (version 2.0+)
- Git
- Au moins 4GB de RAM disponible
- Ports disponibles : 5000, 3000, 8080, 9090, 9093, 5432

## Étapes de Déploiement

### 1. Connexion à la VM

```bash
ssh votre-utilisateur@ip-de-votre-vm
```

### 2. Installation de Docker (si nécessaire)

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo apt install docker-compose-plugin -y

# Vérification
docker --version
docker compose version
```

### 3. Cloner le Projet

```bash
# Cloner depuis GitHub
git clone https://github.com/Herlymba828/inptic-etudiants.git
cd inptic-etudiants
```

### 4. Configuration de l'Environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer le fichier .env avec vos valeurs
nano .env
```

**Variables importantes à configurer dans `.env` :**
- `POSTGRES_PASSWORD` : Mot de passe PostgreSQL
- `SMTP_PASSWORD` : Mot de passe pour l'envoi d'emails
- `SMTP_USER` : Adresse email pour l'envoi
- `JENKINS_ADMIN_PASSWORD` : Mot de passe admin Jenkins
- `GRAFANA_ADMIN_PASSWORD` : Mot de passe admin Grafana

### 5. Démarrage de l'Infrastructure

```bash
# Démarrer tous les services
docker compose up -d

# Vérifier que tous les conteneurs sont en cours d'exécution
docker compose ps

# Voir les logs
docker compose logs -f
```

### 6. Vérification des Services

Une fois démarrés, les services sont accessibles sur :

- **Application Flask** : http://ip-vm:5000
- **Grafana** : http://ip-vm:3000 (admin/admin par défaut)
- **Jenkins** : http://ip-vm:8080
- **Prometheus** : http://ip-vm:9090
- **Alertmanager** : http://ip-vm:9093

### 7. Configuration Post-Déploiement

#### Grafana
1. Connectez-vous à http://ip-vm:3000
2. Changez le mot de passe admin
3. Les dashboards et datasources sont automatiquement provisionnés

#### Jenkins
1. Connectez-vous à http://ip-vm:8080
2. Utilisez les credentials configurés dans `.env`
3. Les jobs sont automatiquement créés via CASC

#### Prometheus & Alertmanager
- Prometheus scrape automatiquement les métriques de l'application
- Alertmanager est configuré pour envoyer des alertes par email

### 8. Commandes Utiles

```bash
# Arrêter tous les services
docker compose down

# Redémarrer un service spécifique
docker compose restart app

# Voir les logs d'un service
docker compose logs -f app

# Reconstruire et redémarrer
docker compose up -d --build

# Nettoyer complètement (attention : supprime les données)
docker compose down -v

# Mettre à jour le code
git pull origin main
docker compose up -d --build
```

### 9. Monitoring et Maintenance

```bash
# Vérifier l'utilisation des ressources
docker stats

# Vérifier l'espace disque
df -h

# Nettoyer les images inutilisées
docker system prune -a
```

## Dépannage

### Les conteneurs ne démarrent pas
```bash
# Vérifier les logs
docker compose logs

# Vérifier les ports utilisés
sudo netstat -tulpn | grep LISTEN
```

### Problèmes de mémoire
```bash
# Augmenter la mémoire swap si nécessaire
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Réinitialiser complètement
```bash
docker compose down -v
docker system prune -a -f
docker compose up -d
```

## Sécurité

1. **Changez tous les mots de passe par défaut** dans `.env`
2. **Configurez un firewall** :
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 5000/tcp
   sudo ufw allow 3000/tcp
   sudo ufw allow 8080/tcp
   sudo ufw enable
   ```
3. **Utilisez HTTPS** en production (nginx + Let's Encrypt)
4. **Sauvegardez régulièrement** la base de données PostgreSQL

## Sauvegarde

```bash
# Sauvegarder la base de données
docker compose exec postgres pg_dump -U inptic_user inptic_db > backup.sql

# Restaurer la base de données
docker compose exec -T postgres psql -U inptic_user inptic_db < backup.sql
```

## Support

Pour plus d'informations, consultez :
- README.md : Vue d'ensemble du projet
- QUICKSTART.md : Guide de démarrage rapide
- docker-compose.yml : Configuration des services
