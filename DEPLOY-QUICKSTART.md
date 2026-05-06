# 🚀 Guide Rapide de Déploiement sur VM

## Option 1 : Déploiement Automatique (Recommandé)

### Depuis votre machine Windows (avec Git Bash)

```bash
# Remplacez par vos informations
make deploy-vm VM=votre-user@ip-de-votre-vm

# Exemple:
make deploy-vm VM=ubuntu@192.168.1.100
```

Le script va automatiquement :
- ✅ Vérifier la connexion SSH
- ✅ Installer Docker et Docker Compose si nécessaire
- ✅ Cloner le projet depuis GitHub
- ✅ Configurer l'environnement
- ✅ Démarrer tous les services

---

## Option 2 : Déploiement Manuel

### 1. Connectez-vous à votre VM

```bash
ssh votre-user@ip-vm
```

### 2. Installez Docker (si nécessaire)

```bash
# Installation rapide de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo apt update
sudo apt install -y docker-compose-plugin

# Déconnectez-vous et reconnectez-vous pour appliquer les changements
exit
ssh votre-user@ip-vm
```

### 3. Clonez le projet

```bash
git clone https://github.com/Herlymba828/inptic-etudiants.git
cd inptic-etudiants
```

### 4. Configurez l'environnement

```bash
# Copiez le fichier d'exemple
cp .env.example .env

# Éditez avec vos valeurs
nano .env
```

**Variables importantes à modifier :**
```env
POSTGRES_PASSWORD=votre_mot_de_passe_securise
SMTP_PASSWORD=votre_mot_de_passe_email
SMTP_USER=votre.email@example.com
JENKINS_ADMIN_PASSWORD=admin_password_securise
GRAFANA_ADMIN_PASSWORD=grafana_password_securise
```

### 5. Démarrez l'infrastructure

```bash
# Option A : Avec le script automatisé
chmod +x scripts/deploy.sh
./scripts/deploy.sh

# Option B : Avec Make
make up

# Option C : Avec Docker Compose directement
docker compose up -d
```

### 6. Vérifiez que tout fonctionne

```bash
# Voir l'état des services
docker compose ps

# Voir les logs
docker compose logs -f
```

---

## 🌐 Accès aux Services

Remplacez `IP-VM` par l'adresse IP de votre VM :

| Service | URL | Identifiants par défaut |
|---------|-----|------------------------|
| **Application Flask** | http://IP-VM:5000 | - |
| **Grafana** | http://IP-VM:3000 | admin / admin |
| **Jenkins** | http://IP-VM:8080 | Voir `.env` |
| **Prometheus** | http://IP-VM:9090 | - |
| **Alertmanager** | http://IP-VM:9093 | - |

---

## 🔧 Commandes Utiles

```bash
# Voir l'état des services
make status
# ou
docker compose ps

# Voir les logs en temps réel
make logs
# ou
docker compose logs -f

# Redémarrer un service
docker compose restart app

# Arrêter tous les services
make down
# ou
docker compose down

# Mettre à jour le code
git pull origin main
docker compose up -d --build

# Sauvegarder la base de données
make backup

# Voir l'utilisation des ressources
docker stats
```

---

## 🔒 Configuration du Firewall (Important!)

```bash
# Autoriser les ports nécessaires
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 5000/tcp  # Application
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 8080/tcp  # Jenkins
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 9093/tcp  # Alertmanager

# Activer le firewall
sudo ufw enable

# Vérifier le statut
sudo ufw status
```

---

## ❌ Dépannage Rapide

### Les services ne démarrent pas

```bash
# Vérifier les logs
docker compose logs

# Vérifier les ports utilisés
sudo netstat -tulpn | grep LISTEN

# Redémarrer Docker
sudo systemctl restart docker
```

### Problème de mémoire

```bash
# Vérifier la mémoire disponible
free -h

# Ajouter du swap si nécessaire
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Réinitialiser complètement

```bash
# ATTENTION : Supprime toutes les données !
docker compose down -v
docker system prune -a -f
docker compose up -d
```

---

## 📚 Documentation Complète

Pour plus de détails, consultez :
- **DEPLOYMENT.md** : Guide complet de déploiement
- **README.md** : Vue d'ensemble du projet
- **QUICKSTART.md** : Guide de démarrage rapide

---

## 🆘 Besoin d'Aide ?

1. Vérifiez les logs : `docker compose logs -f`
2. Consultez DEPLOYMENT.md pour le dépannage détaillé
3. Vérifiez que tous les ports sont ouverts dans le firewall
4. Assurez-vous que Docker a suffisamment de ressources (RAM, CPU)
