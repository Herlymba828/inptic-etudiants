# 🚀 Vue d'Ensemble des Services INPTIC DevOps

## 📊 Architecture Complète

```
┌─────────────────────────────────────────────────────────────────┐
│                     INPTIC DevOps Stack                         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Application    │────▶│   PostgreSQL     │     │     Jenkins      │
│   Flask (5000)   │     │     (5432)       │     │     (8080)       │
│                  │     │                  │     │                  │
│  • API REST      │     │  • Base données  │     │  • CI/CD         │
│  • Métriques     │     │  • Persistence   │     │  • Pipelines     │
│  • Email         │     │  • Backups       │     │  • Webhooks      │
└────────┬─────────┘     └────────┬─────────┘     └──────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌──────────────────┐     ┌──────────────────┐
│   Prometheus     │────▶│  Postgres        │
│     (9090)       │     │  Exporter        │
│                  │     │   (9187)         │
│  • Scraping      │     │                  │
│  • Alertes       │     │  • Métriques DB  │
│  • Stockage      │     │  • Stats         │
└────────┬─────────┘     └──────────────────┘
         │
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  Alertmanager    │     │     Grafana      │
│     (9093)       │     │     (3000)       │
│                  │     │                  │
│  • Notifications │     │  • Dashboards    │
│  • Email         │     │  • Visualisation │
│  • Grouping      │     │  • Alertes       │
└──────────────────┘     └──────────────────┘
```

---

## 🎯 Services Configurés

### 1. 📱 Application Flask

**Port** : 5000  
**Container** : `flask-app`  
**Image** : Custom (build depuis Dockerfile)

#### Fonctionnalités
- ✅ API REST pour gestion des étudiants
- ✅ Interface web (HTML/CSS/JS)
- ✅ Envoi d'emails (SMTP)
- ✅ Métriques Prometheus exposées
- ✅ Connexion PostgreSQL
- ✅ Logs structurés

#### Endpoints Principaux
- `GET /` - Interface web
- `GET /health` - Health check
- `GET /metrics` - Métriques Prometheus
- `POST /api/students` - Créer un étudiant
- `GET /api/students` - Lister les étudiants

#### Configuration
```env
APP_PORT=5000
SECRET_KEY=<généré>
FLASK_ENV=production
SMTP_USER=<votre-email>
SMTP_PASSWORD=<app-password>
```

---

### 2. 🗄️ PostgreSQL

**Port** : 5432  
**Container** : `postgres-db`  
**Image** : `postgres:15-alpine`

#### Fonctionnalités
- ✅ Base de données relationnelle
- ✅ Persistence des données (volume)
- ✅ Health checks automatiques
- ✅ Extensions (uuid-ossp, pg_stat_statements)
- ✅ Scripts d'initialisation automatiques
- ✅ Backups automatisés

#### Configuration
```env
POSTGRES_USER=inptic_user
POSTGRES_PASSWORD=<sécurisé>
POSTGRES_DB=inptic_db
```

#### Commandes Utiles
```bash
# Connexion
make shell-db

# Backup
make backup

# Restore
make restore FILE=backup.sql
```

---

### 3. 📈 Prometheus

**Port** : 9090  
**Container** : `prometheus`  
**Image** : `prom/prometheus:v2.51.0`

#### Fonctionnalités
- ✅ Collecte de métriques (scraping)
- ✅ Stockage time-series
- ✅ Règles d'alertes
- ✅ PromQL pour requêtes
- ✅ Intégration Alertmanager
- ✅ Rechargement à chaud

#### Targets Configurés
| Job | Target | Interval |
|-----|--------|----------|
| flask-app | app:5000 | 15s |
| postgres | postgres-exporter:9187 | 30s |
| prometheus | localhost:9090 | 15s |
| alertmanager | alertmanager:9093 | 15s |
| jenkins | jenkins:8080 | 30s |

#### Alertes Configurées
- `AppDown` - Application inaccessible
- `HighErrorRate` - Taux d'erreurs > 5%
- `HighLatencyP95` - Latence > 1s
- `PostgresDown` - Base de données inaccessible
- `PostgresHighConnections` - Connexions > 80%

#### Configuration
```env
PROMETHEUS_PORT=9090
PROMETHEUS_RETENTION_TIME=15d
PROMETHEUS_SCRAPE_INTERVAL=15s
```

---

### 4. 🔔 Alertmanager

**Port** : 9093  
**Container** : `alertmanager`  
**Image** : `prom/alertmanager:v0.27.0`

#### Fonctionnalités
- ✅ Gestion des alertes Prometheus
- ✅ Notifications par email
- ✅ Grouping des alertes
- ✅ Silencing temporaire
- ✅ Routing configurable
- ✅ Intégration SMTP

#### Configuration Email
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: '<votre-email>'
  smtp_auth_password: '<app-password>'
```

#### Configuration
```env
ALERTMANAGER_PORT=9093
ALERTMANAGER_SMTP_FROM=alertmanager@example.com
ALERTMANAGER_SMTP_TO=admin@example.com
```

---

### 5. 📊 Grafana

**Port** : 3000  
**Container** : `grafana`  
**Image** : `grafana/grafana:10.4.0`

#### Fonctionnalités
- ✅ Dashboards interactifs
- ✅ Visualisation temps réel
- ✅ Alertes visuelles
- ✅ Datasource Prometheus auto-configurée
- ✅ Dashboards provisionnés automatiquement
- ✅ Authentification sécurisée

#### Dashboards Inclus
- **INPTIC RH Dashboard** : Vue d'ensemble complète
  - Métriques application
  - Métriques PostgreSQL
  - Alertes actives
  - Graphiques de performance

#### Configuration
```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<sécurisé>
GRAFANA_PORT=3000
```

#### Accès
- URL : http://localhost:3000
- User : `admin`
- Password : Voir `.env`

---

### 6. 🔧 Jenkins

**Port** : 8080, 50000  
**Container** : `jenkins`  
**Image** : Custom (build depuis jenkins/Dockerfile)

#### Fonctionnalités
- ✅ CI/CD automatisé
- ✅ Configuration as Code (JCasC)
- ✅ Pipelines pré-configurés
- ✅ Intégration Git/GitHub
- ✅ Docker-in-Docker
- ✅ Webhooks GitHub/GitLab

#### Plugins Installés
- Git
- Pipeline
- Docker
- Configuration as Code
- Prometheus Metrics
- Email Extension

#### Jobs Configurés
- **Build & Test** : Compilation et tests automatiques
- **Deploy** : Déploiement automatique
- **Backup** : Sauvegarde automatique de la DB

#### Configuration
```env
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=<sécurisé>
JENKINS_PORT=8080
JENKINS_AGENT_PORT=50000
```

---

### 7. 📊 PostgreSQL Exporter

**Port** : 9187  
**Container** : `postgres-exporter`  
**Image** : `prometheuscommunity/postgres-exporter:v0.15.0`

#### Fonctionnalités
- ✅ Export métriques PostgreSQL vers Prometheus
- ✅ Statistiques de connexions
- ✅ Performance des requêtes
- ✅ Taille des tables
- ✅ Activité des transactions

#### Métriques Exposées
- `pg_stat_activity_count` - Connexions actives
- `pg_stat_database_*` - Stats par base
- `pg_stat_user_tables_*` - Stats par table
- `pg_settings_max_connections` - Configuration

#### Configuration
```env
POSTGRES_EXPORTER_PORT=9187
DATA_SOURCE_NAME=postgresql://user:pass@db:5432/db?sslmode=disable
```

---

## 🔗 Interconnexions

### Flux de Données

```
┌─────────────┐
│   Utilisateur│
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌──────────────┐
│  Flask App  │────▶│  PostgreSQL  │
└──────┬──────┘     └──────────────┘
       │
       │ (métriques)
       ▼
┌─────────────┐     ┌──────────────┐
│ Prometheus  │────▶│ Alertmanager │
└──────┬──────┘     └──────┬───────┘
       │                   │
       │                   │ (email)
       ▼                   ▼
┌─────────────┐     ┌──────────────┐
│   Grafana   │     │    Admin     │
└─────────────┘     └──────────────┘
```

### Flux CI/CD

```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │ (webhook)
       ▼
┌─────────────┐
│   Jenkins   │
└──────┬──────┘
       │
       ├─▶ Build
       ├─▶ Test
       ├─▶ Docker Build
       └─▶ Deploy
```

---

## 📦 Volumes Persistants

| Volume | Service | Contenu |
|--------|---------|---------|
| `postgres_data` | PostgreSQL | Base de données |
| `prometheus_data` | Prometheus | Métriques time-series |
| `grafana_data` | Grafana | Dashboards, users, config |
| `alertmanager_data` | Alertmanager | État des alertes |
| `jenkins_data` | Jenkins | Jobs, builds, config |

---

## 🌐 Réseau

**Nom** : `monitoring`  
**Driver** : `bridge`

Tous les services communiquent via ce réseau Docker interne.

### Résolution DNS Interne

Les services se réfèrent entre eux par leur nom de container :
- `app` → Application Flask
- `db` → PostgreSQL
- `prometheus` → Prometheus
- `grafana` → Grafana
- `jenkins` → Jenkins
- `alertmanager` → Alertmanager
- `postgres-exporter` → PostgreSQL Exporter

---

## 🚀 Démarrage Rapide

```bash
# 1. Configurer l'environnement
cp .env.example .env
nano .env  # Modifier les valeurs

# 2. Vérifier la configuration
./scripts/check-setup.sh

# 3. Démarrer tous les services
make up

# 4. Vérifier l'état
make status

# 5. Accéder aux services
# Application : http://localhost:5000
# Grafana     : http://localhost:3000
# Jenkins     : http://localhost:8080
# Prometheus  : http://localhost:9090
```

---

## 📊 Monitoring & Observabilité

### Métriques Collectées

#### Application
- Requêtes HTTP (total, durée, status)
- Requêtes en cours
- Taille de la queue email
- Erreurs applicatives

#### PostgreSQL
- Connexions actives
- Transactions par seconde
- Taille des tables
- Performance des requêtes
- Cache hit ratio

#### Infrastructure
- CPU, RAM, Disk
- Réseau
- État des conteneurs

### Alertes Configurées

| Alerte | Sévérité | Condition | Action |
|--------|----------|-----------|--------|
| AppDown | Critical | App inaccessible > 1min | Email immédiat |
| HighErrorRate | Warning | Erreurs > 5% pendant 2min | Email |
| PostgresDown | Critical | DB inaccessible > 1min | Email immédiat |
| HighLatency | Warning | P95 > 1s pendant 5min | Email |

---

## 🔒 Sécurité

### Authentification

| Service | User | Password |
|---------|------|----------|
| Grafana | `GRAFANA_ADMIN_USER` | `.env` |
| Jenkins | `JENKINS_ADMIN_USER` | `.env` |
| PostgreSQL | `POSTGRES_USER` | `.env` |

### Bonnes Pratiques Appliquées

- ✅ Mots de passe dans variables d'environnement
- ✅ `.env` dans `.gitignore`
- ✅ Health checks sur tous les services
- ✅ Restart policies configurées
- ✅ Volumes pour persistence
- ✅ Réseau isolé
- ✅ Logs centralisés

---

## 📚 Documentation

- **README.md** : Vue d'ensemble du projet
- **QUICKSTART.md** : Démarrage rapide
- **DEPLOYMENT.md** : Guide de déploiement complet
- **DEPLOY-QUICKSTART.md** : Déploiement rapide sur VM
- **CONFIGURATION.md** : Configuration détaillée
- **SERVICES-OVERVIEW.md** : Ce document

---

## 🆘 Support

### Commandes de Diagnostic

```bash
# État des services
make status

# Logs en temps réel
make logs

# Logs d'un service spécifique
docker compose logs -f <service>

# Health checks
curl http://localhost:5000/health
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health

# Utilisation des ressources
docker stats
```

### Problèmes Courants

1. **Service ne démarre pas** → Vérifier les logs
2. **Port déjà utilisé** → Changer le port dans `.env`
3. **Erreur de connexion DB** → Vérifier `POSTGRES_PASSWORD`
4. **Alertes non envoyées** → Vérifier config SMTP

---

## 🎯 Prochaines Étapes

1. ✅ Tous les services sont configurés
2. ✅ Monitoring complet en place
3. ✅ CI/CD opérationnel
4. 🔄 Déployer sur une VM de production
5. 🔄 Configurer HTTPS avec Let's Encrypt
6. 🔄 Mettre en place des backups automatiques
7. 🔄 Ajouter des tests automatisés

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2024-05-06
