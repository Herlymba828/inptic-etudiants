# Scripts de Déploiement

Ce dossier contient les scripts pour automatiser le déploiement de l'infrastructure INPTIC DevOps.

## Scripts Disponibles

### 🚀 deploy.sh
Script de déploiement local automatisé.

**Usage:**
```bash
./scripts/deploy.sh
```

**Ce qu'il fait:**
- Vérifie que Docker et Docker Compose sont installés
- Vérifie que le fichier `.env` est configuré
- Vérifie la disponibilité des ports requis
- Construit les images Docker
- Démarre tous les services
- Affiche les URLs d'accès

**Prérequis:**
- Docker installé
- Docker Compose installé
- Fichier `.env` configuré

---

### 🌐 deploy-to-vm.sh
Script de déploiement sur une VM distante.

**Usage:**
```bash
./scripts/deploy-to-vm.sh user@ip-vm

# Exemple:
./scripts/deploy-to-vm.sh ubuntu@192.168.1.100
```

**Ce qu'il fait:**
- Vérifie la connexion SSH à la VM
- Installe Docker et Docker Compose si nécessaire
- Clone ou met à jour le dépôt depuis GitHub
- Configure l'environnement
- Propose de démarrer les services automatiquement

**Prérequis:**
- Accès SSH configuré à la VM
- Clé SSH configurée (recommandé) ou mot de passe
- VM avec Ubuntu/Debian (ou distribution compatible)

**Configuration SSH recommandée:**
```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "votre.email@example.com"
ssh-copy-id user@ip-vm

# Tester la connexion
ssh user@ip-vm
```

---

### 🔧 init-alertmanager.sh
Script d'initialisation d'Alertmanager (utilisé par Docker Compose).

**Usage:**
Ce script est appelé automatiquement au démarrage du conteneur Alertmanager.

**Ce qu'il fait:**
- Crée le répertoire de données si nécessaire
- Configure les permissions appropriées
- Démarre Alertmanager avec la configuration

---

## Utilisation avec Make

Les scripts peuvent aussi être appelés via le Makefile :

```bash
# Déploiement local
make deploy

# Déploiement sur VM
make deploy-vm VM=user@ip-vm
```

---

## Permissions

Les scripts doivent être exécutables. Si nécessaire :

```bash
chmod +x scripts/*.sh
```

---

## Dépannage

### Erreur de connexion SSH

```bash
# Vérifier la connexion
ssh -v user@ip-vm

# Vérifier les clés SSH
ssh-add -l

# Ajouter votre clé si nécessaire
ssh-add ~/.ssh/id_ed25519
```

### Docker non trouvé sur la VM

Le script `deploy-to-vm.sh` installe automatiquement Docker. Si l'installation échoue :

```bash
# Se connecter à la VM
ssh user@ip-vm

# Installer manuellement
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Se déconnecter et reconnecter
exit
ssh user@ip-vm
```

### Problème de permissions

```bash
# Sur la VM, ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Appliquer les changements (déconnexion/reconnexion)
exit
ssh user@ip-vm
```

---

## Variables d'Environnement

Les scripts utilisent les variables suivantes (définies dans `.env`) :

- `POSTGRES_PASSWORD` : Mot de passe PostgreSQL
- `SMTP_PASSWORD` : Mot de passe SMTP
- `SMTP_USER` : Utilisateur SMTP
- `JENKINS_ADMIN_PASSWORD` : Mot de passe admin Jenkins
- `GRAFANA_ADMIN_PASSWORD` : Mot de passe admin Grafana

Assurez-vous de configurer ces variables avant le déploiement.

---

## Sécurité

⚠️ **Important:**

1. Ne commitez JAMAIS le fichier `.env` avec des mots de passe réels
2. Utilisez des mots de passe forts pour tous les services
3. Configurez un firewall sur la VM
4. Utilisez HTTPS en production
5. Limitez l'accès SSH par clé uniquement

---

## Support

Pour plus d'informations :
- **DEPLOY-QUICKSTART.md** : Guide rapide de déploiement
- **DEPLOYMENT.md** : Guide complet de déploiement
- **README.md** : Documentation principale du projet
