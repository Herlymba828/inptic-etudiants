# 🚀 INPTIC RH — Démarrage Rapide (5 minutes)

## 1️⃣ Prérequis

```bash
# Vérifier Docker
docker --version
docker compose version

# Si absent, installer :
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

## 2️⃣ Configuration

```bash
# Cloner le projet
git clone https://github.com/votre-org/inptic-rh.git
cd inptic-rh

# Copier et éditer .env
cp .env.example .env
nano .env
```

**Modifier ces 5 lignes minimum** :

```bash
POSTGRES_PASSWORD=VotreMotDePasse123
GMAIL_USER=votre_email@gmail.com
GMAIL_APP_PASSWORD=xxxxxxxxxxxxxxxx    # 16 chars depuis https://myaccount.google.com/apppasswords
NOTIFICATION_EMAIL=destinataire@example.com
GRAFANA_PASSWORD=VotreMotDePasseGrafana
```

**Générer les secrets** :

```bash
python3 -c "import secrets; print('SECRET_KEY=' + secrets.token_hex(32))"
python3 -c "import secrets; print('API_TOKEN=' + secrets.token_hex(32))"
```

Copier les valeurs dans `.env`.

## 3️⃣ Démarrage

```bash
# Avec Make (recommandé)
make up

# OU sans Make
docker compose up -d --build
```

Attendre ~30 secondes que tous les services démarrent.

## 4️⃣ Vérification

```bash
# Vérifier l'état
make status

# Tester l'API
curl http://localhost:5000/health
```

Réponse attendue :

```json
{"status": "healthy", "database": "ok", "email_worker": "ok"}
```

## 5️⃣ Accès

| Service | URL | Login |
|---------|-----|-------|
| **API** | http://localhost:5000 | Bearer token (voir `.env`) |
| **Grafana** | http://localhost:3000 | admin / `${GRAFANA_PASSWORD}` |
| **Jenkins** | http://localhost:8080 | admin / `${JENKINS_ADMIN_PASSWORD}` |
| **Prometheus** | http://localhost:9090 | — |

## 6️⃣ Tester l'API

```bash
# Récupérer le token depuis .env
export API_TOKEN=$(grep "^API_TOKEN=" .env | cut -d'=' -f2)

# Lister les employés
curl -H "Authorization: Bearer $API_TOKEN" \
     http://localhost:5000/api/employes

# Ajouter un employé
curl -X POST \
     -H "Authorization: Bearer $API_TOKEN" \
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

## 7️⃣ CI/CD Automatique (optionnel)

### Configurer le webhook GitHub

1. Aller dans **Settings → Webhooks → Add webhook**
2. **Payload URL** : `http://<votre-ip>:8080/github-webhook/`
3. **Content type** : `application/json`
4. **Events** : Just the push event

```bash
# Obtenir votre IP
make webhook-setup
```

À chaque push sur `main`, Jenkins :
- ✅ Teste le code
- 🔨 Build l'image Docker
- 🚀 Déploie automatiquement
- 📧 Envoie un email de notification

## 📊 Dashboard Grafana

1. Ouvrir http://localhost:3000
2. Login : `admin` / `${GRAFANA_PASSWORD}`
3. Aller dans **Dashboards → INPTIC RH — Tableau de Bord DevOps v4**

Vous verrez en temps réel :
- 👥 Employés actifs
- 📈 Activité (ajouts/suppressions)
- ⏱️ Latence API
- 🗄️ État PostgreSQL

## 🛠️ Commandes utiles

```bash
make help           # Liste toutes les commandes
make logs           # Voir les logs en temps réel
make restart-app    # Redémarrer l'app (zero-downtime)
make backup         # Backup manuel PostgreSQL
make health         # Health check
```

## 🐛 Problème ?

```bash
# Voir les logs
make logs-app

# Redémarrer tout
make restart

# Vérifier la config
cat .env | grep -v "^#" | grep -v "^$"
```

## 📚 Documentation complète

Voir [README.md](README.md) pour :
- Architecture détaillée
- Configuration avancée
- Monitoring & alerting
- Backup & restauration
- Troubleshooting

---

**Besoin d'aide ?** → ${NOTIFICATION_EMAIL}
