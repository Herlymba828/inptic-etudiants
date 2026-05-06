# 🔐 Guide de Connexion - INPTIC Étudiants

Guide rapide pour accéder à tous les services de l'infrastructure INPTIC.

---

## 🌐 Application Principale

### Interface de Gestion des Étudiants

**URL** : http://localhost:5000

**Authentification** : Aucune (accès direct)

**Fonctionnalités** :
- ✅ Dashboard avec statistiques
- ✅ Liste des étudiants (pagination, recherche, filtres)
- ✅ Ajouter un étudiant (avec notification email)
- ✅ Modifier un étudiant
- ✅ Supprimer un étudiant (avec notification email)

**Problème de connexion ?**
```bash
# Vider le cache du navigateur : Ctrl + Shift + Delete
# OU forcer le rechargement : Ctrl + F5
# OU utiliser la navigation privée : Ctrl + Shift + N
# OU essayer : http://127.0.0.1:5000
```

---

## 📊 Grafana - Monitoring et Dashboards

### Accès

**URL** : http://localhost:3001

**Credentials** :
- **Username** : `admin`
- **Password** : `admin123`

### Première Connexion

1. Ouvrez http://localhost:3001
2. Entrez :
   - Email ou nom d'utilisateur : `admin`
   - Mot de passe : `admin123`
3. Cliquez sur "Log in"
4. (Optionnel) Grafana vous demandera de changer le mot de passe

### Dashboards Disponibles

Une fois connecté :
1. Cliquez sur "Dashboards" dans le menu de gauche
2. Vous verrez le dashboard "INPTIC RH" pré-configuré
3. Cliquez dessus pour voir les métriques en temps réel

**Métriques Disponibles** :
- Nombre d'étudiants actifs
- Étudiants ajoutés (total)
- Étudiants supprimés (total)
- Requêtes HTTP par endpoint
- Emails envoyés
- Métriques PostgreSQL

### Problème de Connexion ?

**Si "Nom d'utilisateur ou mot de passe invalides"** :

Le mot de passe a peut-être été changé. Pour réinitialiser :

```bash
# 1. Arrêter Grafana
docker-compose stop grafana

# 2. Supprimer le conteneur
docker rm grafana

# 3. Supprimer le volume (⚠️ perd les données Grafana)
docker volume rm projet-linux_grafana_data

# 4. Redémarrer Grafana
docker-compose up -d grafana

# 5. Attendre 15 secondes
# Puis se connecter avec admin/admin123
```

---

## 🔧 Jenkins - CI/CD

### Accès

**URL** : http://localhost:8080/jenkins

**Credentials** :
- **Username** : `admin`
- **Password** : `admin`

### Configuration

Jenkins est configuré avec Configuration as Code (CasC) :
- Jobs pré-configurés
- Intégration GitHub prête
- Plugins installés automatiquement

### Utilisation

1. Ouvrez http://localhost:8080/jenkins
2. Connectez-vous avec `admin/admin`
3. Les jobs sont disponibles dans le dashboard

---

## 📈 Prometheus - Métriques

### Accès

**URL** : http://localhost:9090

**Authentification** : Aucune

### Utilisation

**Vérifier les Targets** :
1. Allez sur http://localhost:9090/targets
2. Vérifiez que toutes les cibles sont "UP" :
   - Flask App (app:5000)
   - PostgreSQL Exporter (postgres-exporter:9187)
   - Prometheus (prometheus:9090)

**Requêtes Utiles** :

```promql
# Nombre d'étudiants actifs
etudiants_actifs

# Total d'étudiants ajoutés
etudiants_ajoutes_total

# Requêtes HTTP par endpoint
http_requests_total

# Emails envoyés
emails_envoyes_total
```

---

## 🚨 Alertmanager - Gestion des Alertes

### Accès

**URL** : http://localhost:9093

**Authentification** : Aucune

### Utilisation

1. Ouvrez http://localhost:9093
2. Consultez les alertes actives
3. Les alertes sont envoyées par email à `herlymba828@gmail.com`

**Types d'Alertes Configurées** :
- Application down
- Database down
- High error rate
- High response time

---

## 🗄️ PostgreSQL - Base de Données

### Accès Direct (depuis l'hôte)

⚠️ **Par défaut, PostgreSQL n'est PAS exposé sur l'hôte** (sécurité).

Pour y accéder depuis votre machine :

**Option 1 : Via Docker Exec**
```bash
# Entrer dans le conteneur PostgreSQL
docker exec -it postgres-db psql -U inptic_user -d inptic_db

# Commandes SQL utiles
\dt                    # Lister les tables
SELECT * FROM etudiants;  # Voir tous les étudiants
\q                     # Quitter
```

**Option 2 : Exposer le Port (pour outils externes)**

Modifiez `docker-compose.yml` :
```yaml
db:
  ports:
    - "5432:5432"  # Décommenter cette ligne
```

Puis redémarrez :
```bash
docker-compose restart db
```

**Credentials** :
- Host : `localhost` (ou `db` depuis Docker)
- Port : `5432`
- Database : `inptic_db`
- Username : `inptic_user`
- Password : `changeme_postgres_password_2024`

**Chaîne de connexion** :
```
postgresql://inptic_user:changeme_postgres_password_2024@localhost:5432/inptic_db
```

---

## 🔍 Vérification Rapide

### Tester Tous les Services

```bash
# Vérifier l'état
docker ps

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

### Voir les Logs

```bash
# Tous les services
docker-compose logs -f

# Un service spécifique
docker logs flask-app -f
docker logs grafana -f
docker logs prometheus -f
```

---

## 🚨 Problèmes Courants

### 1. "Connexion refusée" (ERR_CONNECTION_REFUSED)

**Solutions** :
1. Vérifier que le service est en cours d'exécution : `docker ps`
2. Vider le cache du navigateur : `Ctrl + Shift + Delete`
3. Utiliser la navigation privée : `Ctrl + Shift + N`
4. Redémarrer le service : `docker restart <nom_service>`

### 2. "Mot de passe invalide" sur Grafana

**Solution** :
```bash
# Réinitialiser Grafana
docker-compose stop grafana
docker rm grafana
docker volume rm projet-linux_grafana_data
docker-compose up -d grafana

# Attendre 15 secondes puis se connecter avec admin/admin
```

### 3. Page Blanche ou Erreur 500

**Solutions** :
1. Vérifier les logs : `docker logs <nom_service> --tail 50`
2. Redémarrer le service : `docker restart <nom_service>`
3. Vérifier que PostgreSQL est accessible

### 4. Emails Non Reçus

**Vérifications** :
1. Vérifier les logs Flask : `docker logs flask-app -f`
2. Vérifier la configuration dans `.env`
3. Vérifier les spams dans `herlymba828@gmail.com`
4. Redémarrer Flask : `docker restart flask-app`

---

## 📱 Accès depuis un Autre Appareil

Pour accéder aux services depuis un autre appareil sur le même réseau :

1. **Trouver l'IP de votre machine** :
   ```bash
   # Windows
   ipconfig
   
   # Chercher "Adresse IPv4" (ex: 192.168.1.100)
   ```

2. **Accéder depuis l'autre appareil** :
   ```
   http://192.168.1.100:5000    (Flask)
   http://192.168.1.100:3001    (Grafana)
   http://192.168.1.100:8080/jenkins    (Jenkins)
   http://192.168.1.100:9090    (Prometheus)
   ```

3. **Configurer le Firewall** :
   - Autoriser les ports 5000, 3001, 8080, 9090, 9093
   - Sur Windows : Panneau de configuration → Pare-feu Windows

---

## 🔐 Changer les Mots de Passe

### Grafana

**Via l'Interface** :
1. Connectez-vous à http://localhost:3001
2. Cliquez sur votre profil (en bas à gauche)
3. Allez dans "Change password"
4. Entrez l'ancien et le nouveau mot de passe

**Via la Ligne de Commande** :
```bash
docker exec -it grafana grafana-cli admin reset-admin-password nouveaumotdepasse
docker restart grafana
```

### Jenkins

**Via l'Interface** :
1. Connectez-vous à http://localhost:8080/jenkins
2. Cliquez sur "admin" (en haut à droite)
3. Cliquez sur "Configure"
4. Changez le mot de passe

### PostgreSQL

```bash
docker exec -it postgres-db psql -U inptic_user -d inptic_db -c "ALTER USER inptic_user WITH PASSWORD 'nouveau_mot_de_passe';"
```

Puis mettez à jour `.env` et redémarrez Flask :
```bash
docker restart flask-app
```

---

## 📚 Documentation Complète

Pour plus d'informations, consultez :
- `README.md` - Vue d'ensemble du projet
- `TROUBLESHOOTING.md` - Guide de dépannage détaillé
- `ACCES.md` - Tous les credentials (local uniquement)
- `RESUME-CONFIGURATION.md` - Résumé de configuration

---

## ✅ Checklist de Connexion

Avant de commencer, vérifiez :

- [ ] Docker Desktop est en cours d'exécution
- [ ] Tous les services sont "Up" : `docker ps`
- [ ] Vous utilisez les bons ports (5000, 3001, 8080, 9090)
- [ ] Le cache du navigateur est vidé si nécessaire
- [ ] Vous utilisez les bons credentials (admin/admin)

---

## 📞 Besoin d'Aide ?

**En cas de problème** :
1. Consultez `TROUBLESHOOTING.md`
2. Vérifiez les logs : `docker-compose logs -f`
3. Redémarrez les services : `docker-compose restart`
4. Contactez : herlymba828@gmail.com

---

**🎉 Bon travail avec INPTIC Étudiants !**

*Dernière mise à jour : 6 mai 2026*
