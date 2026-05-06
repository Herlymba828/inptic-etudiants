# 📊 Guide des Métriques - Dashboard Grafana INPTIC

Ce document détaille toutes les métriques disponibles dans le dashboard Grafana et leur signification.

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'Ensemble](#vue-densemble)
2. [Activité en Temps Réel](#activité-en-temps-réel)
3. [PostgreSQL - Base de Données](#postgresql---base-de-données)
4. [Ressources Système](#ressources-système)
5. [Alertes et Monitoring](#alertes-et-monitoring)
6. [Requêtes PromQL Utilisées](#requêtes-promql-utilisées)

---

## 📊 VUE D'ENSEMBLE

### 👥 Étudiants Actifs
**Métrique** : `etudiants_actifs`  
**Type** : Gauge  
**Description** : Nombre total d'étudiants actuellement enregistrés dans la base de données.

**Seuils d'alerte** :
- 🟢 Vert : < 50 étudiants
- 🟡 Jaune : 50-100 étudiants
- 🔴 Rouge : > 100 étudiants

**Utilité** : Surveiller la croissance de la base d'étudiants.

---

### ✅ Total Ajouts
**Métrique** : `etudiants_ajoutes_total`  
**Type** : Counter  
**Description** : Nombre cumulé d'étudiants ajoutés depuis le démarrage de l'application.

**Utilité** : 
- Mesurer l'activité d'inscription
- Calculer le taux d'ajout moyen
- Détecter les pics d'inscription

---

### 🗑️ Total Suppressions
**Métrique** : `etudiants_supprimes_total`  
**Type** : Counter  
**Description** : Nombre cumulé d'étudiants supprimés depuis le démarrage.

**Utilité** :
- Surveiller le taux de désabonnement (churn)
- Identifier les périodes de nettoyage de données
- Calculer le ratio ajouts/suppressions

---

### 📧 Emails Envoyés
**Métrique** : `emails_envoyes_total`  
**Type** : Counter  
**Description** : Nombre total d'emails de notification envoyés (ajouts + suppressions).

**Utilité** :
- Vérifier que les notifications fonctionnent
- Surveiller la charge du service SMTP
- Détecter les échecs d'envoi (si le compteur ne bouge pas)

---

### 🌐 Requêtes/sec
**Métrique** : `sum(rate(http_requests_total[1m]))`  
**Type** : Rate  
**Description** : Nombre de requêtes HTTP par seconde (moyenne sur 1 minute).

**Seuils d'alerte** :
- 🟢 Vert : < 100 req/s
- 🟡 Jaune : 100-500 req/s
- 🔴 Rouge : > 500 req/s

**Utilité** :
- Mesurer la charge de l'application
- Détecter les pics de trafic
- Planifier la scalabilité

---

### 🔌 État Services
**Métrique** : `up{job="flask-app"}`  
**Type** : Gauge (0 ou 1)  
**Description** : Indique si le service Flask est accessible par Prometheus.

**Valeurs** :
- 🟢 `1` (UP) : Service accessible
- 🔴 `0` (DOWN) : Service inaccessible

**Utilité** :
- Surveillance de disponibilité
- Alerte immédiate en cas de panne
- SLA monitoring

---

## 📈 ACTIVITÉ EN TEMPS RÉEL

### 📊 Activité Étudiants (Ajouts/Suppressions)
**Métriques** :
- `rate(etudiants_ajoutes_total[1m]) * 60` → Ajouts par minute
- `rate(etudiants_supprimes_total[1m]) * 60` → Suppressions par minute

**Type** : Time Series  
**Description** : Graphique temporel montrant l'évolution des opérations CRUD.

**Utilité** :
- Identifier les heures de pointe
- Détecter les anomalies (pics inhabituels)
- Analyser les tendances d'utilisation

**Calculs disponibles** :
- **Mean** : Moyenne sur la période
- **Max** : Pic maximum observé

---

### 🌐 Requêtes HTTP par Endpoint
**Métrique** : `rate(http_requests_total[1m])`  
**Type** : Time Series  
**Description** : Taux de requêtes par endpoint (GET, POST, PUT, DELETE).

**Labels** :
- `method` : GET, POST, PUT, DELETE
- `endpoint` : /api/etudiants, /api/stats, /health, etc.

**Utilité** :
- Identifier les endpoints les plus sollicités
- Détecter les endpoints lents
- Optimiser les routes critiques

**Exemple de légende** :
```
POST /api/etudiants
GET /api/etudiants
DELETE /api/etudiants/<id>
GET /api/stats
```

---

## 🗄️ POSTGRESQL - BASE DE DONNÉES

### 🔌 PostgreSQL Status
**Métrique** : `pg_up`  
**Type** : Gauge (0 ou 1)  
**Description** : État de connexion à PostgreSQL.

**Valeurs** :
- 🟢 `1` (UP) : Base de données accessible
- 🔴 `0` (DOWN) : Base de données inaccessible

**Alerte critique** : Si DOWN pendant > 30 secondes.

---

### 🔗 Connexions Actives
**Métrique** : `pg_stat_activity_count`  
**Type** : Gauge  
**Description** : Nombre de connexions actives à PostgreSQL.

**Seuils d'alerte** :
- 🟢 Vert : < 50 connexions
- 🟡 Jaune : 50-100 connexions
- 🔴 Rouge : > 100 connexions

**Utilité** :
- Détecter les fuites de connexions (connection leaks)
- Surveiller la charge de la base
- Ajuster le pool de connexions

**Limite par défaut PostgreSQL** : 100 connexions

---

### 💾 Taille Base de Données
**Métrique** : `pg_database_size_bytes{datname="inptic_prod_db"}`  
**Type** : Gauge  
**Description** : Taille totale de la base de données en bytes.

**Utilité** :
- Planifier l'espace disque
- Détecter la croissance anormale
- Planifier les backups

**Conversion** :
- 1 MB = 1,048,576 bytes
- 1 GB = 1,073,741,824 bytes

---

### 📊 Transactions PostgreSQL
**Métriques** :
- `rate(pg_stat_database_xact_commit{datname="inptic_prod_db"}[1m])` → Commits/sec
- `rate(pg_stat_database_xact_rollback{datname="inptic_prod_db"}[1m])` → Rollbacks/sec

**Type** : Time Series  
**Description** : Taux de transactions validées vs annulées.

**Utilité** :
- Surveiller la santé des transactions
- Détecter les erreurs applicatives (rollbacks élevés)
- Mesurer la charge transactionnelle

**Ratio sain** : Commits >> Rollbacks (> 95% commits)

---

## ⚙️ RESSOURCES SYSTÈME

### 🖥️ CPU Usage
**Métrique** : `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)`  
**Type** : Gauge (%)  
**Description** : Pourcentage d'utilisation CPU (moyenne sur 1 minute).

**Seuils d'alerte** :
- 🟢 Vert : < 60%
- 🟡 Jaune : 60-80%
- 🟠 Orange : 80-90%
- 🔴 Rouge : > 90%

**Utilité** :
- Détecter la surcharge CPU
- Identifier les processus gourmands
- Planifier l'upgrade matériel

**Note** : Calculé en soustrayant le temps idle du temps total.

---

### 💾 Memory Usage
**Métrique** : `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`  
**Type** : Gauge (%)  
**Description** : Pourcentage de mémoire utilisée.

**Seuils d'alerte** :
- 🟢 Vert : < 70%
- 🟡 Jaune : 70-85%
- 🟠 Orange : 85-95%
- 🔴 Rouge : > 95%

**Utilité** :
- Détecter les fuites mémoire (memory leaks)
- Surveiller la pression mémoire
- Ajuster les limites Docker

**Différence** :
- `MemAvailable` : Mémoire disponible (inclut cache)
- `MemFree` : Mémoire libre (sans cache)

---

### 💿 Disk Usage
**Métrique** : `(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100`  
**Type** : Gauge (%)  
**Description** : Pourcentage d'espace disque utilisé sur la partition racine.

**Seuils d'alerte** :
- 🟢 Vert : < 75%
- 🟡 Jaune : 75-90%
- 🟠 Orange : 90-95%
- 🔴 Rouge : > 95%

**Utilité** :
- Prévenir le manque d'espace disque
- Planifier le nettoyage
- Surveiller la croissance des logs

**Alerte critique** : Si > 95%, risque de crash applicatif.

---

### 🌐 Network I/O
**Métriques** :
- `rate(node_network_receive_bytes_total[1m])` → Bytes reçus/sec
- `rate(node_network_transmit_bytes_total[1m])` → Bytes envoyés/sec

**Type** : Time Series  
**Description** : Débit réseau entrant et sortant par interface.

**Utilité** :
- Surveiller la bande passante
- Détecter les attaques DDoS
- Identifier les transferts anormaux

**Labels** :
- `device` : eth0, lo, docker0, etc.

---

## 🚨 ALERTES ET MONITORING

### 📊 Répartition des Requêtes HTTP
**Métrique** : `sum by (endpoint) (http_requests_total)`  
**Type** : Pie Chart  
**Description** : Distribution des requêtes par endpoint.

**Utilité** :
- Identifier les endpoints les plus utilisés
- Optimiser les routes critiques
- Détecter les abus (endpoints spammés)

**Exemple de répartition** :
```
GET /api/etudiants : 45%
POST /api/etudiants : 25%
GET /api/stats : 15%
DELETE /api/etudiants/<id> : 10%
GET /health : 5%
```

---

### 🎯 Targets Prometheus
**Métrique** : `up`  
**Type** : Table  
**Description** : Liste de tous les targets Prometheus avec leur statut.

**Colonnes** :
- **Job** : Nom du service (flask-app, postgres, prometheus, etc.)
- **Instance** : Adresse du target
- **Status** : 1 (UP) ou 0 (DOWN)

**Utilité** :
- Vue d'ensemble de l'infrastructure
- Détecter les services down
- Vérifier la configuration Prometheus

**Targets attendus** :
1. `flask-app` (app:5000)
2. `postgres` (postgres-exporter:9187)
3. `prometheus` (localhost:9090)
4. `alertmanager` (alertmanager:9093)
5. `jenkins` (jenkins:8080)

---

## 📐 REQUÊTES PROMQL UTILISÉES

### Métriques Applicatives

```promql
# Étudiants actifs
etudiants_actifs

# Total ajouts
etudiants_ajoutes_total

# Total suppressions
etudiants_supprimes_total

# Emails envoyés
emails_envoyes_total

# Requêtes HTTP totales
sum(rate(http_requests_total[1m]))

# Requêtes par endpoint
rate(http_requests_total[1m])

# Ajouts par minute
rate(etudiants_ajoutes_total[1m]) * 60

# Suppressions par minute
rate(etudiants_supprimes_total[1m]) * 60
```

### Métriques PostgreSQL

```promql
# Status PostgreSQL
pg_up

# Connexions actives
pg_stat_activity_count

# Taille base de données
pg_database_size_bytes{datname="inptic_prod_db"}

# Transactions commits
rate(pg_stat_database_xact_commit{datname="inptic_prod_db"}[1m])

# Transactions rollbacks
rate(pg_stat_database_xact_rollback{datname="inptic_prod_db"}[1m])
```

### Métriques Système

```promql
# CPU Usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100

# Network RX
rate(node_network_receive_bytes_total[1m])

# Network TX
rate(node_network_transmit_bytes_total[1m])
```

### Métriques de Monitoring

```promql
# Status des services
up

# Répartition requêtes
sum by (endpoint) (http_requests_total)
```

---

## 🔔 ALERTES CONFIGURÉES

### Application Down
```yaml
alert: ApplicationDown
expr: up{job="flask-app"} == 0
for: 1m
severity: critical
```

### Database Down
```yaml
alert: DatabaseDown
expr: pg_up == 0
for: 30s
severity: critical
```

### High Error Rate
```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 5m
severity: warning
```

### High CPU Usage
```yaml
alert: HighCPUUsage
expr: (100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
for: 10m
severity: warning
```

### High Memory Usage
```yaml
alert: HighMemoryUsage
expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
for: 5m
severity: warning
```

### Disk Space Low
```yaml
alert: DiskSpaceLow
expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 90
for: 5m
severity: critical
```

---

## 📊 INTERPRÉTATION DES MÉTRIQUES

### Scénarios Normaux

**Activité normale** :
- Étudiants actifs : croissance régulière
- Ajouts/Suppressions : ratio 10:1 (10 ajouts pour 1 suppression)
- Requêtes HTTP : < 50 req/s
- CPU : < 50%
- Memory : < 70%
- Disk : < 75%

### Scénarios d'Alerte

**Pic d'inscription** :
- ✅ Ajouts/min : augmentation soudaine
- ✅ Requêtes HTTP : pic sur POST /api/etudiants
- ⚠️ CPU : augmentation temporaire
- ✅ Emails envoyés : augmentation proportionnelle

**Problème de performance** :
- 🔴 CPU : > 80% pendant > 10 min
- 🔴 Memory : > 90%
- 🔴 Connexions PostgreSQL : > 80
- 🔴 Requêtes HTTP : temps de réponse élevé

**Panne de service** :
- 🔴 up{job="flask-app"} = 0
- 🔴 pg_up = 0
- 🔴 Requêtes HTTP : 0 req/s
- 🔴 Alertmanager : envoi d'email

---

## 🎯 BONNES PRATIQUES

### Surveillance Quotidienne
1. Vérifier l'état des services (tous UP)
2. Surveiller les ressources système (< 70%)
3. Vérifier les alertes actives
4. Analyser les tendances d'utilisation

### Surveillance Hebdomadaire
1. Analyser la croissance de la base de données
2. Vérifier les logs d'erreur
3. Optimiser les requêtes lentes
4. Planifier la scalabilité

### Surveillance Mensuelle
1. Analyser les tendances long terme
2. Ajuster les seuils d'alerte
3. Planifier les upgrades
4. Réviser les backups

---

## 📚 RESSOURCES

- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Grafana](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [PostgreSQL Exporter](https://github.com/prometheus-community/postgres_exporter)
- [Node Exporter](https://github.com/prometheus/node_exporter)

---

## 🆘 DÉPANNAGE

### Dashboard vide
1. Vérifier que Prometheus collecte les métriques : http://localhost:9090/targets
2. Vérifier la datasource Grafana : Configuration → Data Sources
3. Tester une requête PromQL simple : `up`

### Métriques manquantes
1. Vérifier les logs de l'application : `docker logs flask-app`
2. Vérifier l'endpoint /metrics : `curl http://localhost:5000/metrics`
3. Vérifier la configuration Prometheus : `prometheus/prometheus.yml`

### Alertes non reçues
1. Vérifier Alertmanager : http://localhost:9093
2. Vérifier la configuration SMTP : `prometheus/alertmanager.yml`
3. Tester l'envoi d'email : `docker logs alertmanager`

---

**📅 Dernière mise à jour** : 6 mai 2026  
**👤 Auteur** : Équipe DevOps INPTIC  
**📧 Contact** : herlymba828@gmail.com
