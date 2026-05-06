# 🎓 INPTIC RH — Système de Gestion des Employés

Application Flask de gestion RH avec stack DevOps complète : monitoring (Prometheus + Grafana), alerting (Alertmanager), CI/CD (Jenkins), et déploiement automatisé.

---

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Démarrage](#démarrage)
- [CI/CD Automatique](#cicd-automatique)
- [Monitoring & Alerting](#monitoring--alerting)
- [Backup & Restauration](#backup--restauration)
- [Commandes utiles](#commandes-utiles)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     INPTIC RH Stack                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Flask   │  │PostgreSQL│  │Prometheus│  │ Grafana  │  │
│  │  :5000   │  │  :5432   │  │  :9090   │  │  :3000   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │ Jenkins  │  │Alertmgr  │  │ Postgres │                │
│  │  :8080   │  │  :9093   │  │ Exporter │                │
│  └──────────┘  └──────────┘  └──────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Services** :
- **Flask API** (port 5000) — CRUD employés, authentification Bearer token
- **PostgreSQL** (port 5432) — Base de données avec backup automatique quotidien
- **Prometheus** (port 9090) — Collecte des métriques (rétention 30j/5GB)
- **Grafana** (port 3000) — Dashboards temps réel
- **Alertmanager** (port 9093) — Notifications email des alertes
- **Jenkins** (port 8080) — Pipeline CI/CD automatique sur push Git
- **Postgres Exporter** — Métriques PostgreSQL pour Prometheus

---

## 📦 Prérequis

- **Docker** ≥ 24.0
- **Docker Compose** ≥ 2.20
- **Make** (optionnel, mais recommandé)
- **Git**
- **Python 3.11+** (pour les tests locaux)

### Installation Docker (Ubuntu/Debian)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

---

## 🚀 Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/votre-org/inptic-rh.git
cd inptic-rh
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
nano .env  # ou vim, code, etc.
```

**Variables critiques à modifier** :

```bash
# PostgreSQL
POSTGRES_PASSWORD=VotreMotDePasseSecurise

# Gmail SMTP (mot de passe d'application 16 chars)
GMAIL_USER=votre_adresse@gmail.com
GMAIL_APP_PASSWORD=xxxxxxxxxxxxxxxx
NOTIFICATION_EMAIL=destinataire@example.com

# Sécurité (générez avec : python3 -c "import secrets; print(secrets.token_hex(32))")
SECRET_KEY=<générez-une-clé-aléatoire>
API_TOKEN=<générez-un-token-aléatoire>

# Grafana
GRAFANA_PASSWORD=VotreMotDePasseGrafana

# Jenkins
JENKINS_ADMIN_PASSWORD=VotreMotDePasseJenkins
GIT_ORG=votre-organisation-github
GIT_USERNAME=votre-username
GIT_TOKEN=<token-github-avec-droits-repo>
```

### 3. Créer un mot de passe d'application Gmail

1. Aller sur https://myaccount.google.com/apppasswords
2. Créer un mot de passe d'application pour "Mail"
3. Copier le mot de passe (16 caractères, sans espaces) dans `.env`

---

## ▶️ Démarrage

### Avec Make (recommandé)

```bash
make up          # Démarre tous les services
make status      # Affiche l'état des services
make logs        # Suit les logs en temps réel
```

### Sans Make

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

### Vérification

Attendez ~30 secondes que tous les services démarrent, puis :

```bash
make health      # Vérifie la santé de l'application
```

Ou manuellement :

```bash
curl http://localhost:5000/health
```

Réponse attendue :

```json
{
  "status": "healthy",
  "database": "ok",
  "email_worker": "ok"
}
```

---

## 🌐 Accès aux services

| Service | URL | Credentials |
|---------|-----|-------------|
| **API Flask** | http://localhost:5000 | Bearer token (voir `.env` → `API_TOKEN`) |
| **Grafana** | http://localhost:3000 | admin / `${GRAFANA_PASSWORD}` |
| **Prometheus** | http://localhost:9090 | Aucun |
| **Alertmanager** | http://localhost:9093 | Aucun |
| **Jenkins** | http://localhost:8080 | admin / `${JENKINS_ADMIN_PASSWORD}` |

### Tester l'API

```bash
# Lister les employés (nécessite le token)
curl -H "Authorization: Bearer ${API_TOKEN}" \
     http://localhost:5000/api/employes

# Ajouter un employé
curl -X POST \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{
       "nom": "Dupont",
       "prenom": "Jean",
       "email": "jean.dupont@example.com",
       "filiere": "Informatique",
       "annee": "2024"
     }' \
     http://localhost:5000/api/employes
```

---

## 🔄 CI/CD Automatique

### Configuration du webhook Git

Le pipeline Jenkins se déclenche automatiquement à chaque push sur `main`.

#### GitHub

1. Aller dans **Settings → Webhooks → Add webhook**
2. **Payload URL** : `http://<votre-ip>:8080/github-webhook/`
3. **Content type** : `application/json`
4. **Events** : Just the push event
5. **Active** : ✅

#### GitLab

1. Aller dans **Settings → Webhooks**
2. **URL** : `http://<votre-ip>:8080/project/inptic-rh`
3. **Trigger** : Push events
4. **SSL verification** : désactiver si HTTP

#### Obtenir votre IP

```bash
make webhook-setup    # Affiche les instructions + votre IP
```

### Pipeline

Le `Jenkinsfile` exécute automatiquement :

1. **Checkout** — Clone le code
2. **Lint** — Vérifie la syntaxe Python (pyflakes)
3. **Tests** — Tests unitaires (SQLite en mémoire)
4. **Build Docker** — Construit l'image avec tags (build number, commit SHA, latest)
5. **Déploiement** — Redémarre l'app (zero-downtime)
6. **Health Check** — Vérifie `/health`, `/metrics`, `/api/employes`
7. **Nettoyage** — Supprime les anciennes images

**Notifications email** envoyées à chaque build (succès/échec).

---

## 📊 Monitoring & Alerting

### Grafana

Dashboard **INPTIC RH — Tableau de Bord DevOps v4** :

- 👥 Employés actifs
- ✅ Total ajouts / 🗑️ Total suppressions
- 📧 Emails envoyés / 📬 Queue email
- ⚡ Requêtes en cours
- 📈 Activité RH (ajouts/suppressions par minute)
- 🌐 Requêtes HTTP par endpoint
- ⏱️ Latence API (p50, p95, p99)
- ❌ Taux d'erreurs HTTP 5xx
- 🗄️ Connexions PostgreSQL actives
- 📊 Transactions PostgreSQL/s

**Accès** : http://localhost:3000 (admin / `${GRAFANA_PASSWORD}`)

### Prometheus

**Métriques exposées** :

- `etudiants_actifs` — Nombre d'employés en base
- `etudiants_ajoutes_total` — Total ajouts
- `etudiants_supprimes_total` — Total suppressions
- `emails_envoyes_total` — Emails envoyés avec succès
- `email_queue_size` — Taille de la queue email
- `http_requests_total` — Requêtes HTTP (method, endpoint, status)
- `http_request_duration_seconds` — Latence (histogram)
- `http_requests_in_progress` — Requêtes en cours
- `pg_*` — Métriques PostgreSQL (connexions, transactions, etc.)

**Accès** : http://localhost:9090

### Alertmanager

**Alertes configurées** :

| Alerte | Seuil | Durée | Sévérité |
|--------|-------|-------|----------|
| **AppDown** | up == 0 | 1 min | critical |
| **HighErrorRate** | Erreurs 5xx > 5% | 2 min | warning |
| **HighLatencyP95** | p95 > 1s | 5 min | warning |
| **EmailQueueFull** | Queue > 150 | 5 min | warning |
| **HighConcurrentRequests** | > 50 requêtes | 2 min | warning |
| **PostgresDown** | up == 0 | 1 min | critical |
| **PostgresHighConnections** | > 80% max | 5 min | warning |
| **PostgresSlowQueries** | > 30s | 5 min | warning |

**Notifications** : Email envoyé à `${NOTIFICATION_EMAIL}` (configuré dans `.env`)

**Accès** : http://localhost:9093

---

## 💾 Backup & Restauration

### Backup automatique

Un backup PostgreSQL est créé **automatiquement tous les jours** à minuit.

- **Emplacement** : `./postgres/backups/`
- **Format** : `backup_YYYYMMDD_HHMMSS.sql.gz`
- **Rétention** : 7 jours (les backups plus anciens sont supprimés automatiquement)

### Backup manuel

```bash
make backup
```

### Restauration

```bash
make restore    # Restaure le dernier backup (demande confirmation)
```

**⚠️ ATTENTION** : La restauration écrase toutes les données actuelles !

### Restauration d'un backup spécifique

```bash
gunzip -c postgres/backups/backup_20240506_120000.sql.gz \
  | docker exec -i postgres-db sh -c \
    'PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER $POSTGRES_DB'
```

---

## 🛠️ Commandes utiles

### Gestion des services

```bash
make up                  # Démarre tous les services
make down                # Arrête tous les services
make restart             # Redémarre tous les services
make restart-app         # Redémarre seulement l'app (zero-downtime)
make status              # Affiche l'état des services
make ps                  # Alias pour status
```

### Logs

```bash
make logs                # Tous les services (follow)
make logs-app            # Application Flask
make logs-jenkins        # Jenkins
make logs-db             # PostgreSQL
```

### Monitoring

```bash
make health              # Health check de l'application
make reload-prometheus   # Recharge la config Prometheus à chaud
make reload-alertmanager # Recharge la config Alertmanager à chaud
```

### Migrations DB

```bash
make db-migrate MSG="Ajout colonne statut"   # Crée une migration
make db-upgrade                               # Applique les migrations
make db-history                               # Historique des migrations
```

### Shell

```bash
make shell-app           # Shell dans le conteneur Flask
make shell-db            # psql dans PostgreSQL
make shell-jenkins       # Shell dans Jenkins
```

### Nettoyage

```bash
make clean               # Supprime les conteneurs (préserve les volumes)
make clean-images        # Supprime les anciennes images Docker
make clean-all           # ⚠️ DESTRUCTIF — Supprime tout y compris les volumes
```

---

## 🐛 Troubleshooting

### L'application ne démarre pas

```bash
# Vérifier les logs
make logs-app

# Vérifier la santé de PostgreSQL
docker exec postgres-db pg_isready -U inptic

# Reconstruire l'image
make build
make restart-app
```

### Jenkins ne se connecte pas au dépôt Git

1. Vérifier que `GIT_TOKEN` dans `.env` a les droits `repo` + `admin:repo_hook`
2. Aller dans Jenkins → Manage Jenkins → Credentials
3. Vérifier que `git-credentials` est bien configuré

### Les emails ne sont pas envoyés

1. Vérifier que `GMAIL_APP_PASSWORD` est un **mot de passe d'application** (16 chars)
2. Vérifier les logs : `make logs-app | grep email`
3. Tester manuellement :

```bash
docker exec flask-app python3 -c "
import sys; sys.path.insert(0, '.')
from email_service import send_email
result = send_email('Test', 'Corps du test', 'destinataire@example.com')
print('✅ OK' if result else '❌ Échec')
"
```

### Prometheus ne scrape pas l'application

```bash
# Vérifier que l'app expose /metrics
curl http://localhost:5000/metrics

# Vérifier la config Prometheus
curl http://localhost:9090/api/v1/targets

# Recharger la config
make reload-prometheus
```

### Grafana : "No data"

1. Vérifier que Prometheus fonctionne : http://localhost:9090
2. Aller dans Grafana → Configuration → Data sources → Prometheus → Test
3. Vérifier que les métriques existent dans Prometheus :
   ```
   http://localhost:9090/graph?g0.expr=etudiants_actifs
   ```

### Le webhook Git ne déclenche pas Jenkins

1. Vérifier que Jenkins est accessible depuis Internet (ou depuis GitHub/GitLab)
2. Tester le webhook manuellement :
   ```bash
   curl -X POST http://<votre-ip>:8080/github-webhook/
   ```
3. Vérifier les logs Jenkins : `make logs-jenkins`
4. Fallback : Jenkins poll SCM toutes les 5 min automatiquement

---

## 📚 Documentation

- **API** : http://localhost:5000/ (liste des endpoints)
- **Métriques** : http://localhost:5000/metrics
- **Health** : http://localhost:5000/health
- **Prometheus** : http://localhost:9090/graph
- **Grafana** : http://localhost:3000/dashboards
- **Jenkins** : http://localhost:8080/job/inptic-rh/

---

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/ma-feature`)
3. Commit les changements (`git commit -m 'Ajout de ma feature'`)
4. Push vers la branche (`git push origin feature/ma-feature`)
5. Ouvrir une Pull Request

Le pipeline Jenkins testera automatiquement votre PR.

---

## 📄 Licence

© 2026 INPTIC — Tous droits réservés

---

## 👥 Équipe

**INPTIC DevOps Team**

Pour toute question : ${NOTIFICATION_EMAIL}
