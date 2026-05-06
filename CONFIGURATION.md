# 📋 Guide de Configuration INPTIC DevOps

Ce document explique comment configurer tous les services de l'infrastructure.

## 📁 Structure des Fichiers de Configuration

```
.
├── .env                          # Variables d'environnement (NE PAS COMMITER!)
├── .env.example                  # Template des variables
├── docker-compose.yml            # Orchestration des services
│
├── app/                          # Application Flask
│   ├── config.py                 # Configuration app
│   ├── models.py                 # Modèles de données
│   └── requirements.txt          # Dépendances Python
│
├── prometheus/                   # Monitoring
│   ├── prometheus.yml            # Config Prometheus
│   ├── alerts.yml                # Règles d'alertes
│   └── alertmanager.yml          # Config Alertmanager
│
├── grafana/                      # Visualisation
│   ├── datasources/              # Sources de données
│   ├── dashboards/               # Tableaux de bord
│   ├── alerting/                 # Alertes Grafana
│   └── notifiers/                # Notifications
│
├── jenkins/                      # CI/CD
│   ├── Dockerfile                # Image Jenkins personnalisée
│   ├── plugins.txt               # Plugins Jenkins
│   └── casc/                     # Configuration as Code
│       ├── jenkins.yml           # Config principale
│       ├── jobs.yml              # Jobs CI/CD
│       └── credentials.yml       # Credentials
│
└── postgres/                     # Base de données
    └── init/                     # Scripts d'initialisation
        └── 01_extensions.sql     # Extensions PostgreSQL
```

---

## 🔧 Configuration Étape par Étape

### 1️⃣ Fichier .env (OBLIGATOIRE)

```bash
# Copier le template
cp .env.example .env

# Éditer avec vos valeurs
nano .env  # ou vim, code, etc.
```

#### Variables Critiques à Modifier

| Variable | Description | Exemple |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL | `MySecureP@ssw0rd2024` |
| `SECRET_KEY` | Clé secrète Flask | Générer avec Python (voir ci-dessous) |
| `SMTP_USER` | Email pour notifications | `votre.email@gmail.com` |
| `SMTP_PASSWORD` | Mot de passe email | App Password Gmail |
| `GRAFANA_ADMIN_PASSWORD` | Mot de passe Grafana | `SecureGrafana123!` |
| `JENKINS_ADMIN_PASSWORD` | Mot de passe Jenkins | `SecureJenkins123!` |

#### Générer une SECRET_KEY Sécurisée

```bash
# Méthode 1 : Python
python -c "import secrets; print(secrets.token_hex(32))"

# Méthode 2 : OpenSSL
openssl rand -hex 32

# Méthode 3 : En ligne
# https://randomkeygen.com/
```

#### Configurer Gmail pour SMTP

1. **Activer la validation en 2 étapes** sur votre compte Google
2. **Générer un mot de passe d'application** :
   - Aller sur : https://myaccount.google.com/apppasswords
   - Sélectionner "Autre (nom personnalisé)"
   - Nommer : "INPTIC DevOps"
   - Copier le mot de passe généré (16 caractères)
3. **Utiliser ce mot de passe** dans `SMTP_PASSWORD`

---

### 2️⃣ PostgreSQL

#### Configuration Automatique

Le fichier `postgres/init/01_extensions.sql` est exécuté automatiquement au premier démarrage :

```sql
-- Extensions PostgreSQL utiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
```

#### Connexion Manuelle

```bash
# Depuis l'hôte
docker exec -it postgres-db psql -U inptic_user -d inptic_db

# Ou via Make
make shell-db
```

#### Backup et Restore

```bash
# Créer un backup
make backup

# Restaurer un backup
make restore FILE=backups/backup_20240506_120000.sql
```

---

### 3️⃣ Prometheus

#### Fichier : `prometheus/prometheus.yml`

Configuration des targets à scraper :

```yaml
scrape_configs:
  - job_name: 'flask-app'
    static_configs:
      - targets: ['app:5000']
  
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
```

#### Fichier : `prometheus/alerts.yml`

Règles d'alertes personnalisables :

```yaml
groups:
  - name: inptic-rh-app
    rules:
      - alert: AppDown
        expr: up{job="flask-app"} == 0
        for: 1m
```

#### Recharger la Configuration

```bash
# Sans redémarrage
make reload-prometheus

# Ou manuellement
curl -X POST http://localhost:9090/-/reload
```

---

### 4️⃣ Alertmanager

#### Fichier : `prometheus/alertmanager.yml`

Configuration des notifications :

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'votre.email@gmail.com'
  smtp_auth_password: 'votre_app_password'

route:
  receiver: 'email-admin'

receivers:
  - name: 'email-admin'
    email_configs:
      - to: 'admin@example.com'
```

**⚠️ Important** : Utilisez les variables du fichier `.env` pour les credentials.

---

### 5️⃣ Grafana

#### Accès Initial

- **URL** : http://localhost:3000
- **User** : `admin` (ou valeur de `GRAFANA_ADMIN_USER`)
- **Password** : Valeur de `GRAFANA_ADMIN_PASSWORD` dans `.env`

#### Datasources (Auto-provisionnées)

Fichier : `grafana/datasources/prometheus.yml`

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
```

#### Dashboards (Auto-provisionnés)

- `grafana/dashboards/inptic-rh.json` : Dashboard principal
- Automatiquement chargé au démarrage

#### Ajouter des Plugins

Dans `.env` :
```env
GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
```

---

### 6️⃣ Jenkins

#### Accès Initial

- **URL** : http://localhost:8080
- **User** : Valeur de `JENKINS_ADMIN_USER` dans `.env`
- **Password** : Valeur de `JENKINS_ADMIN_PASSWORD` dans `.env`

#### Configuration as Code (JCasC)

Fichier : `jenkins/casc/jenkins.yml`

```yaml
jenkins:
  securityRealm:
    local:
      users:
        - id: "${JENKINS_ADMIN_USER}"
          password: "${JENKINS_ADMIN_PASSWORD}"
```

#### Jobs CI/CD

Fichier : `jenkins/casc/jobs.yml`

Définit les pipelines automatiquement.

#### Plugins

Fichier : `jenkins/plugins.txt`

Liste des plugins installés automatiquement :
```
git:latest
workflow-aggregator:latest
docker-workflow:latest
```

---

### 7️⃣ Application Flask

#### Fichier : `app/config.py`

Configuration chargée depuis les variables d'environnement :

```python
import os

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY')
    SQLALCHEMY_DATABASE_URI = f"postgresql://{os.getenv('POSTGRES_USER')}:..."
```

#### Métriques Prometheus

Endpoint : http://localhost:5000/metrics

Métriques exposées :
- `http_requests_total`
- `http_request_duration_seconds`
- `email_queue_size`
- etc.

---

## 🔒 Sécurité

### Checklist de Sécurité

- [ ] Tous les mots de passe par défaut ont été changés
- [ ] Le fichier `.env` n'est PAS commité dans Git
- [ ] Les mots de passe font au moins 16 caractères
- [ ] SMTP utilise un App Password (pas le mot de passe principal)
- [ ] `FLASK_DEBUG=0` en production
- [ ] Firewall configuré (voir ci-dessous)
- [ ] HTTPS configuré (recommandé en production)

### Configuration Firewall

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
```

---

## 🧪 Validation de la Configuration

### Script de Vérification

```bash
# Vérifier que tous les fichiers sont présents
./scripts/check-setup.sh
```

### Validation Docker Compose

```bash
# Valider la syntaxe
docker compose config

# Lister les services
docker compose config --services
```

### Test des Services

```bash
# Démarrer tous les services
make up

# Vérifier l'état
make status

# Tester les endpoints
curl http://localhost:5000/health
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

---

## 📊 Ports Utilisés

| Service | Port | URL |
|---------|------|-----|
| Application Flask | 5000 | http://localhost:5000 |
| Grafana | 3000 | http://localhost:3000 |
| Jenkins | 8080 | http://localhost:8080 |
| Prometheus | 9090 | http://localhost:9090 |
| Alertmanager | 9093 | http://localhost:9093 |
| PostgreSQL | 5432 | localhost:5432 |
| Postgres Exporter | 9187 | http://localhost:9187 |

---

## 🔄 Mise à Jour de la Configuration

### Modifier une Configuration

1. **Éditer le fichier** de configuration
2. **Recharger** le service :

```bash
# Prometheus (sans redémarrage)
make reload-prometheus

# Autres services (avec redémarrage)
docker compose restart <service>

# Exemple
docker compose restart grafana
```

### Appliquer de Nouvelles Variables .env

```bash
# Recréer les conteneurs avec les nouvelles variables
docker compose up -d --force-recreate
```

---

## 🆘 Dépannage

### Les services ne démarrent pas

```bash
# Voir les logs
docker compose logs <service>

# Exemple
docker compose logs app
docker compose logs prometheus
```

### Erreur de connexion PostgreSQL

```bash
# Vérifier que PostgreSQL est prêt
docker compose logs db

# Tester la connexion
docker exec postgres-db pg_isready -U inptic_user
```

### Prometheus ne scrape pas les métriques

```bash
# Vérifier les targets
curl http://localhost:9090/api/v1/targets

# Vérifier la config
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

---

## 📚 Ressources

- [Documentation Docker Compose](https://docs.docker.com/compose/)
- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Grafana](https://grafana.com/docs/)
- [Documentation Jenkins](https://www.jenkins.io/doc/)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

## 🔗 Fichiers Liés

- **DEPLOYMENT.md** : Guide de déploiement complet
- **DEPLOY-QUICKSTART.md** : Guide rapide de déploiement
- **README.md** : Vue d'ensemble du projet
- **QUICKSTART.md** : Démarrage rapide
