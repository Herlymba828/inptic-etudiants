# 🔄 Mise à Jour du Serveur de Production

Guide pour déployer le nouveau dashboard Grafana complet sur le serveur de production.

---

## 📋 CE QUI A ÉTÉ AJOUTÉ

### ✨ Nouveau Dashboard Grafana

Le dashboard a été complètement refait avec :

#### 📊 **Section 1 : Vue d'Ensemble**
- 👥 Étudiants actifs (avec seuils d'alerte)
- ✅ Total ajouts
- 🗑️ Total suppressions  
- 📧 Emails envoyés
- 🌐 Requêtes/seconde
- 🔌 État des services (UP/DOWN)

#### 📈 **Section 2 : Activité en Temps Réel**
- 📊 Graphique des ajouts/suppressions par minute
- 🌐 Requêtes HTTP par endpoint avec détails

#### 🗄️ **Section 3 : PostgreSQL**
- 🔌 Status de la base de données
- 🔗 Nombre de connexions actives
- 💾 Taille de la base de données
- 📊 Transactions (commits vs rollbacks)

#### ⚙️ **Section 4 : Ressources Système**
- 🖥️ CPU Usage (gauge avec seuils)
- 💾 Memory Usage (gauge avec seuils)
- 💿 Disk Usage (gauge avec seuils)
- 🌐 Network I/O (RX/TX)

#### 🚨 **Section 5 : Alertes et Monitoring**
- 📊 Répartition des requêtes HTTP (pie chart)
- 🎯 Liste des targets Prometheus (table)

### 📚 Documentation Ajoutée

- **DASHBOARD-METRICS.md** : Guide complet de toutes les métriques avec explications détaillées

---

## 🚀 DÉPLOIEMENT SUR LE SERVEUR

### Étape 1 : Connexion SSH

```bash
ssh root@192.168.206.132
```

### Étape 2 : Mise à Jour du Code

```bash
cd /opt/inptic-etudiants

# Récupérer les dernières modifications
git pull origin main
```

**Résultat attendu** :
```
remote: Enumerating objects: ...
Mise à jour aac8975..714a22b
Fast-forward
 DASHBOARD-METRICS.md                | 563 ++++++++++++++++++++++++++++
 grafana/dashboards/inptic-rh.json   | 567 ++++++++++++++++++++++++----
 2 files changed, 1080 insertions(+), 50 deletions(-)
```

### Étape 3 : Redémarrer Grafana

```bash
# Redémarrer Grafana pour charger le nouveau dashboard
docker restart grafana

# Attendre 15 secondes
sleep 15

# Vérifier que Grafana est UP
curl -s http://localhost:3001/api/health
```

**Résultat attendu** : `{"database":"ok","version":"10.4.0"}`

### Étape 4 : Vérification

```bash
# Vérifier que le dashboard est chargé
curl -s http://admin:GrafanaInptic2024@localhost:3001/api/dashboards/uid/inptic-rh-devops | python3 -c "import sys,json; d=json.load(sys.stdin); print('Dashboard:', d['dashboard']['title'])"
```

**Résultat attendu** : `Dashboard: 🎓 INPTIC RH - Dashboard Complet DevOps`

---

## 🌐 ACCÈS AU NOUVEAU DASHBOARD

### URL
```
http://192.168.206.132:3001
```

### Credentials
- **Username** : `admin`
- **Password** : `GrafanaInptic2024`

### Navigation
1. Connectez-vous à Grafana
2. Cliquez sur "Dashboards" dans le menu de gauche
3. Sélectionnez "🎓 INPTIC RH - Dashboard Complet DevOps"
4. Le dashboard se charge avec toutes les métriques

---

## ⚠️ NOTES IMPORTANTES

### Métriques Système (Node Exporter)

Les métriques système (CPU, Memory, Disk, Network) nécessitent **Node Exporter** qui n'est **pas encore installé**.

Pour l'instant, ces panneaux afficheront "No data" :
- 🖥️ CPU Usage
- 💾 Memory Usage
- 💿 Disk Usage
- 🌐 Network I/O

### Installation de Node Exporter (Optionnel)

Si vous voulez activer les métriques système, ajoutez Node Exporter au `docker-compose.yml` :

```yaml
  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: node-exporter
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'
    ports:
      - "9100:9100"
    restart: unless-stopped
    networks:
      - monitoring
```

Puis ajoutez dans `prometheus/prometheus.yml` :

```yaml
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          service: 'node-exporter'
```

Redémarrez :
```bash
docker-compose up -d
```

---

## 📊 MÉTRIQUES DISPONIBLES IMMÉDIATEMENT

### ✅ Fonctionnelles (avec données)
- 👥 Étudiants actifs
- ✅ Total ajouts
- 🗑️ Total suppressions
- 📧 Emails envoyés
- 🌐 Requêtes/seconde
- 🔌 État des services
- 📊 Activité en temps réel
- 🌐 Requêtes HTTP par endpoint
- 🔌 PostgreSQL Status
- 🔗 Connexions actives PostgreSQL
- 💾 Taille base de données
- 📊 Transactions PostgreSQL
- 📊 Répartition des requêtes
- 🎯 Targets Prometheus

### ⏳ En attente de Node Exporter
- 🖥️ CPU Usage
- 💾 Memory Usage
- 💿 Disk Usage
- 🌐 Network I/O

---

## 🧪 TESTER LE DASHBOARD

### 1. Ajouter un Étudiant

```bash
curl -X POST http://192.168.206.132:5000/api/etudiants \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Test",
    "prenom": "Dashboard",
    "email": "test.dashboard@inptic.edu",
    "filiere": "Informatique",
    "annee": "L3"
  }'
```

### 2. Vérifier les Métriques

Retournez sur Grafana et observez :
- ✅ "Total Ajouts" augmente de 1
- 👥 "Étudiants Actifs" augmente de 1
- 📧 "Emails Envoyés" augmente de 1
- 📊 Graphique "Activité en Temps Réel" montre un pic
- 🌐 "Requêtes HTTP" montre POST /api/etudiants

### 3. Supprimer l'Étudiant de Test

```bash
# Récupérer l'ID
ID=$(curl -s http://192.168.206.132:5000/api/etudiants | python3 -c "import sys,json; d=json.load(sys.stdin); print([e['id'] for e in d['data'] if e['email']=='test.dashboard@inptic.edu'][0])")

# Supprimer
curl -X DELETE http://192.168.206.132:5000/api/etudiants/$ID
```

### 4. Vérifier à Nouveau

- 🗑️ "Total Suppressions" augmente de 1
- 👥 "Étudiants Actifs" revient à la valeur précédente
- 📧 "Emails Envoyés" augmente de 1 (email de suppression)

---

## 📚 DOCUMENTATION

### Consulter le Guide des Métriques

```bash
# Sur le serveur
cat /opt/inptic-etudiants/DASHBOARD-METRICS.md

# Ou télécharger localement
scp root@192.168.206.132:/opt/inptic-etudiants/DASHBOARD-METRICS.md .
```

Le fichier `DASHBOARD-METRICS.md` contient :
- Description détaillée de chaque métrique
- Seuils d'alerte configurés
- Requêtes PromQL utilisées
- Scénarios d'interprétation
- Guide de dépannage

---

## 🔧 PERSONNALISATION

### Modifier les Seuils d'Alerte

Éditez `grafana/dashboards/inptic-rh.json` et cherchez les sections `thresholds` :

```json
"thresholds": {
  "mode": "absolute",
  "steps": [
    {"color": "green", "value": null},
    {"color": "yellow", "value": 50},
    {"color": "red", "value": 100}
  ]
}
```

### Ajouter de Nouveaux Panneaux

1. Connectez-vous à Grafana
2. Ouvrez le dashboard
3. Cliquez sur "Add panel"
4. Configurez la requête PromQL
5. Sauvegardez
6. Exportez le JSON : Settings → JSON Model
7. Copiez dans `grafana/dashboards/inptic-rh.json`

---

## 🚨 DÉPANNAGE

### Dashboard ne se charge pas

```bash
# Vérifier les logs Grafana
docker logs grafana --tail 50

# Vérifier que le fichier existe
docker exec grafana ls -la /etc/grafana/provisioning/dashboards/

# Forcer le rechargement
docker restart grafana
```

### Datasource "Prometheus" non trouvée

```bash
# Vérifier l'UID de la datasource
curl -s http://admin:GrafanaInptic2024@localhost:3001/api/datasources | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['uid'])"
```

**Résultat attendu** : `prometheus`

Si différent, éditez `grafana/datasources/prometheus.yml` et ajoutez :
```yaml
uid: prometheus
```

### Panneaux "No data"

```bash
# Vérifier que Prometheus collecte les métriques
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool

# Tester une requête PromQL
curl -s 'http://localhost:9090/api/v1/query?query=up' | python3 -m json.tool

# Vérifier l'endpoint /metrics de Flask
curl http://localhost:5000/metrics
```

---

## ✅ CHECKLIST DE DÉPLOIEMENT

- [ ] Connexion SSH au serveur
- [ ] `git pull origin main` exécuté
- [ ] Grafana redémarré
- [ ] Dashboard accessible sur http://192.168.206.132:3001
- [ ] Connexion avec admin/GrafanaInptic2024
- [ ] Dashboard "INPTIC RH - Dashboard Complet DevOps" visible
- [ ] Métriques principales affichent des données
- [ ] Test d'ajout d'étudiant effectué
- [ ] Métriques mises à jour en temps réel
- [ ] Documentation DASHBOARD-METRICS.md consultée

---

## 📞 SUPPORT

En cas de problème :

1. Consultez `TROUBLESHOOTING.md`
2. Vérifiez les logs : `docker logs grafana`
3. Testez Prometheus : http://192.168.206.132:9090
4. Contactez : herlymba828@gmail.com

---

**🎉 Félicitations ! Votre dashboard Grafana est maintenant complet et opérationnel.**

**📅 Date de mise à jour** : 6 mai 2026  
**👤 Auteur** : Équipe DevOps INPTIC
