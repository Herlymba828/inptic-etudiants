# 🔧 Guide de Dépannage INPTIC Étudiants

Ce guide vous aide à résoudre les problèmes courants rencontrés avec l'infrastructure INPTIC.

---

## 🚨 Problèmes Courants

### 1. ERR_CONNECTION_REFUSED ou ERR_EMPTY_RESPONSE

**Symptômes** :
- Le navigateur affiche "Cette page n'est pas disponible"
- Message : "localhost a refusé de se connecter"
- Erreur : `ERR_CONNECTION_REFUSED` ou `ERR_EMPTY_RESPONSE`

**Solutions** :

#### A. Vérifier que les services sont en cours d'exécution

```bash
docker ps
```

Vous devriez voir 7 conteneurs en état "Up" :
- flask-app
- postgres-db
- prometheus
- grafana
- jenkins
- alertmanager
- postgres-exporter

#### B. Vider le cache du navigateur

**Dans Edge/Chrome** :
1. Appuyez sur `Ctrl + Shift + Delete`
2. Cochez "Images et fichiers en cache"
3. Cliquez sur "Effacer les données"

**OU** :
- Appuyez sur `Ctrl + F5` pour forcer le rechargement

#### C. Utiliser la navigation privée

Ouvrez une fenêtre de navigation privée (`Ctrl + Shift + N`) et essayez :
```
http://localhost:5000    (Flask App)
http://localhost:3001    (Grafana)
http://localhost:8080    (Jenkins)
http://localhost:9090    (Prometheus)
```

#### D. Essayer avec l'adresse IP

```
http://127.0.0.1:5000
http://127.0.0.1:3001
```

#### E. Redémarrer le service spécifique

```bash
# Redémarrer Flask
docker restart flask-app

# Redémarrer Grafana
docker restart grafana

# Redémarrer tous les services
docker-compose restart
```

---

### 2. Grafana en État "Restarting"

**Symptômes** :
- `docker ps` montre Grafana avec STATUS "Restarting"
- Impossible d'accéder à http://localhost:3001

**Diagnostic** :

```bash
docker logs grafana --tail 50
```

**Causes Courantes** :

#### A. Erreur de configuration d'alerting

**Message d'erreur** :
```
Error: failure to map file alerting.yml: could not find addresses in settings
```

**Solution** :
Le fichier `grafana/alerting/alerting.yml` contient une adresse email invalide ou une variable d'environnement non interpolée.

Éditez `grafana/alerting/alerting.yml` et remplacez :
```yaml
addresses: ${NOTIFICATION_EMAIL}
```

Par une adresse email valide :
```yaml
addresses: admin@example.com
```

Puis redémarrez :
```bash
docker restart grafana
```

#### B. Problème de permissions

```bash
# Vérifier les permissions du volume
docker volume inspect projet-linux_grafana_data

# Recréer le volume si nécessaire
docker-compose down
docker volume rm projet-linux_grafana_data
docker-compose up -d grafana
```

---

### 3. PostgreSQL - Connection Refused

**Symptômes** :
- Flask ne peut pas se connecter à PostgreSQL
- Erreur : "could not connect to server"

**Solutions** :

#### A. Vérifier que PostgreSQL est en cours d'exécution

```bash
docker ps --filter "name=postgres-db"
```

Le STATUS doit être "Up" et "healthy".

#### B. Vérifier les logs PostgreSQL

```bash
docker logs postgres-db --tail 50
```

#### C. Vérifier les variables d'environnement

Assurez-vous que `.env` contient :
```bash
POSTGRES_USER=inptic_user
POSTGRES_PASSWORD=changeme_postgres_password_2024
POSTGRES_DB=inptic_db
POSTGRES_HOST=db
```

#### D. Redémarrer PostgreSQL

```bash
docker restart postgres-db
```

#### E. Recréer la base de données

⚠️ **ATTENTION : Cela supprimera toutes les données !**

```bash
docker-compose down
docker volume rm projet-linux_postgres_data
docker-compose up -d db
```

---

### 4. Flask App - 500 Internal Server Error

**Symptômes** :
- L'application Flask retourne une erreur 500
- Les pages ne se chargent pas

**Diagnostic** :

```bash
docker logs flask-app --tail 100
```

**Causes Courantes** :

#### A. Erreur de connexion à la base de données

Vérifiez que PostgreSQL est accessible :
```bash
docker exec flask-app curl http://db:5432
```

#### B. Variables d'environnement manquantes

Vérifiez que toutes les variables sont définies dans `.env` :
```bash
docker exec flask-app env | grep POSTGRES
```

#### C. Erreur dans le code Python

Vérifiez les logs pour identifier l'erreur :
```bash
docker logs flask-app -f
```

Puis redémarrez :
```bash
docker restart flask-app
```

---

### 5. Prometheus - Targets Down

**Symptômes** :
- Dans Prometheus (http://localhost:9090/targets), certaines cibles sont "DOWN"

**Solutions** :

#### A. Vérifier que les services sont accessibles

```bash
# Tester Flask metrics
curl http://localhost:5000/metrics

# Tester Postgres Exporter
curl http://localhost:9187/metrics
```

#### B. Vérifier la configuration Prometheus

```bash
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

#### C. Redémarrer Prometheus

```bash
docker restart prometheus
```

---

### 6. Jenkins - Setup Wizard Apparaît

**Symptômes** :
- Jenkins demande le mot de passe initial
- Configuration as Code (CasC) ne fonctionne pas

**Solutions** :

#### A. Vérifier les variables d'environnement

Dans `docker-compose.yml`, assurez-vous que :
```yaml
environment:
  - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
  - CASC_JENKINS_CONFIG=/var/jenkins_home/casc
```

#### B. Vérifier les fichiers CasC

```bash
docker exec jenkins ls -la /var/jenkins_home/casc/
```

Vous devriez voir :
- jenkins.yml
- jobs.yml
- credentials.yml

#### C. Recréer Jenkins

```bash
docker-compose down
docker volume rm projet-linux_jenkins_data
docker-compose up -d jenkins
```

---

### 7. Emails Non Envoyés

**Symptômes** :
- Aucun email reçu lors de l'ajout/suppression d'étudiant
- Message dans les logs : "Configuration email manquante"

**Solutions** :

#### A. Configurer les credentials Gmail

Dans `.env`, configurez :
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre.email@gmail.com
SMTP_PASSWORD=votre_app_password_gmail
NOTIFICATION_EMAIL=destinataire@example.com
```

**Important** : Utilisez un "App Password" Gmail, pas votre mot de passe normal.

Pour créer un App Password :
1. Allez sur https://myaccount.google.com/security
2. Activez la validation en 2 étapes
3. Allez dans "Mots de passe des applications"
4. Créez un nouveau mot de passe pour "Mail"

#### B. Redémarrer Flask après modification

```bash
docker-compose restart app
```

#### C. Tester l'envoi d'email

Ajoutez un étudiant via l'interface et vérifiez les logs :
```bash
docker logs flask-app -f
```

---

### 8. Port Déjà Utilisé

**Symptômes** :
- Erreur au démarrage : "port is already allocated"
- `docker-compose up` échoue

**Solutions** :

#### A. Identifier le processus utilisant le port

```powershell
# Sur Windows PowerShell
netstat -ano | Select-String ":5000"
```

#### B. Arrêter le processus

```powershell
# Trouver le PID dans la sortie précédente
Stop-Process -Id <PID> -Force
```

#### C. Changer le port dans docker-compose.yml

Si vous ne pouvez pas libérer le port, modifiez `docker-compose.yml` :
```yaml
ports:
  - "5001:5000"  # Utiliser 5001 au lieu de 5000
```

---

### 9. Volumes Docker Corrompus

**Symptômes** :
- Services qui redémarrent en boucle
- Erreurs de permissions
- Données manquantes

**Solution** : Recréer tous les volumes

⚠️ **ATTENTION : Cela supprimera toutes les données !**

```bash
# Arrêter tous les services
docker-compose down

# Supprimer tous les volumes
docker volume rm projet-linux_postgres_data
docker volume rm projet-linux_grafana_data
docker volume rm projet-linux_prometheus_data
docker volume rm projet-linux_jenkins_data
docker volume rm projet-linux_alertmanager_data

# Redémarrer
docker-compose up -d
```

---

### 10. Problèmes de Réseau Docker

**Symptômes** :
- Services ne peuvent pas communiquer entre eux
- Erreur : "network not found"

**Solutions** :

#### A. Recréer le réseau

```bash
docker-compose down
docker network rm projet-linux_monitoring
docker-compose up -d
```

#### B. Vérifier les réseaux

```bash
docker network ls
docker network inspect projet-linux_monitoring
```

---

## 🔍 Commandes de Diagnostic Utiles

### Vérifier l'état de tous les services

```bash
docker ps -a
```

### Voir les logs en temps réel

```bash
# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f app
docker-compose logs -f grafana
docker-compose logs -f prometheus
```

### Vérifier l'utilisation des ressources

```bash
docker stats
```

### Inspecter un conteneur

```bash
docker inspect flask-app
docker inspect postgres-db
```

### Tester la connectivité réseau

```bash
# Depuis Flask vers PostgreSQL
docker exec flask-app ping db

# Depuis Flask vers Prometheus
docker exec flask-app curl http://prometheus:9090
```

### Vérifier les volumes

```bash
docker volume ls
docker volume inspect projet-linux_postgres_data
```

---

## 🚀 Redémarrage Complet

Si rien ne fonctionne, voici la procédure de redémarrage complet :

```bash
# 1. Arrêter tous les services
docker-compose down

# 2. (Optionnel) Supprimer les volumes pour repartir de zéro
docker-compose down -v

# 3. Nettoyer les images inutilisées
docker system prune -f

# 4. Reconstruire les images
docker-compose build --no-cache

# 5. Redémarrer tous les services
docker-compose up -d

# 6. Vérifier l'état
docker ps

# 7. Suivre les logs
docker-compose logs -f
```

---

## 📞 Obtenir de l'Aide

### Vérifier les logs détaillés

```bash
# Logs avec timestamps
docker-compose logs -f --timestamps

# Logs depuis une date spécifique
docker-compose logs --since 2026-05-06T10:00:00
```

### Exporter les logs pour analyse

```bash
docker-compose logs > logs-complets.txt
```

### Vérifier la configuration

```bash
# Valider docker-compose.yml
docker-compose config

# Voir les variables d'environnement
docker-compose config | grep -A 10 environment
```

---

## 🔗 Liens Utiles

- **Documentation Docker** : https://docs.docker.com/
- **Documentation Grafana** : https://grafana.com/docs/
- **Documentation Prometheus** : https://prometheus.io/docs/
- **Documentation Jenkins** : https://www.jenkins.io/doc/
- **Documentation Flask** : https://flask.palletsprojects.com/

---

## ✅ Checklist de Vérification

Avant de demander de l'aide, vérifiez :

- [ ] Tous les services sont en état "Up" (`docker ps`)
- [ ] Les logs ne montrent pas d'erreurs critiques
- [ ] Le fichier `.env` est correctement configuré
- [ ] Les ports ne sont pas utilisés par d'autres applications
- [ ] Le cache du navigateur a été vidé
- [ ] Docker Desktop est en cours d'exécution (Windows/Mac)
- [ ] Vous avez suffisamment d'espace disque
- [ ] Vous avez suffisamment de RAM (minimum 4 GB recommandé)

---

*Dernière mise à jour : 6 mai 2026*
