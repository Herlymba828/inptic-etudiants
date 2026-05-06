#!/bin/bash

# ============================================================
# Script d'Installation Automatique - INPTIC Étudiants
# CentOS Stream 10
# ============================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    log_info "Utilisez: sudo bash $0"
    exit 1
fi

log_info "=== Installation INPTIC Étudiants sur CentOS Stream 10 ==="
echo ""

# ============================================================
# Étape 1 : Mise à jour du système
# ============================================================
log_info "Étape 1/10 : Mise à jour du système..."
dnf update -y > /dev/null 2>&1
dnf install -y git curl wget nano vim net-tools > /dev/null 2>&1
log_success "Système mis à jour"

# ============================================================
# Étape 2 : Désactivation de SELinux
# ============================================================
log_info "Étape 2/10 : Configuration de SELinux..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
log_success "SELinux configuré en mode permissive"

# ============================================================
# Étape 3 : Installation de Docker
# ============================================================
log_info "Étape 3/10 : Installation de Docker..."

# Vérifier si Docker est déjà installé
if command -v docker &> /dev/null; then
    log_warning "Docker est déjà installé"
else
    dnf install -y dnf-plugins-core > /dev/null 2>&1
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
    systemctl start docker
    systemctl enable docker > /dev/null 2>&1
    log_success "Docker installé : $(docker --version)"
fi

# ============================================================
# Étape 4 : Installation de Docker Compose
# ============================================================
log_info "Étape 4/10 : Vérification de Docker Compose..."
if command -v docker-compose &> /dev/null; then
    log_success "Docker Compose installé : $(docker-compose --version)"
else
    log_warning "Installation de Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installé"
fi

# ============================================================
# Étape 5 : Configuration du Firewall
# ============================================================
log_info "Étape 5/10 : Configuration du firewall..."
dnf install -y firewalld > /dev/null 2>&1
systemctl start firewalld
systemctl enable firewalld > /dev/null 2>&1

# Ouvrir les ports
firewall-cmd --permanent --add-service=ssh > /dev/null 2>&1
firewall-cmd --permanent --add-service=http > /dev/null 2>&1
firewall-cmd --permanent --add-service=https > /dev/null 2>&1
firewall-cmd --permanent --add-port=5000/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=3001/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=8080/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=9090/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=9093/tcp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

log_success "Firewall configuré"

# ============================================================
# Étape 6 : Clonage du projet
# ============================================================
log_info "Étape 6/10 : Clonage du projet..."
INSTALL_DIR="/opt/inptic-etudiants"

if [ -d "$INSTALL_DIR" ]; then
    log_warning "Le répertoire $INSTALL_DIR existe déjà"
    read -p "Voulez-vous le supprimer et recommencer ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf $INSTALL_DIR
        log_info "Répertoire supprimé"
    else
        log_error "Installation annulée"
        exit 1
    fi
fi

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR
git clone https://github.com/Herlymba828/inptic-etudiants.git . > /dev/null 2>&1
log_success "Projet cloné dans $INSTALL_DIR"

# ============================================================
# Étape 7 : Configuration des variables d'environnement
# ============================================================
log_info "Étape 7/10 : Configuration des variables d'environnement..."

if [ -f ".env" ]; then
    log_warning "Le fichier .env existe déjà"
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    log_info "Backup créé : .env.backup.*"
fi

cp .env.production .env

# Générer des mots de passe aléatoires
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
SECRET_KEY=$(openssl rand -base64 32 | tr -d "=+/")
GRAFANA_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
JENKINS_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/")

# Remplacer les valeurs dans .env
sed -i "s/CHANGEZ_MOI_postgres_prod_password_SECURE_2024/$POSTGRES_PASSWORD/g" .env
sed -i "s/CHANGEZ_MOI_secret_key_production_MINIMUM_32_CARACTERES_ALEATOIRES/$SECRET_KEY/g" .env
sed -i "s/CHANGEZ_MOI_grafana_prod_password_SECURE/$GRAFANA_PASSWORD/g" .env
sed -i "s/CHANGEZ_MOI_jenkins_prod_password_SECURE/$JENKINS_PASSWORD/g" .env
sed -i "s/CHANGEZ_MOI_jwt_secret_production_MINIMUM_64_CARACTERES_ALEATOIRES/$JWT_SECRET/g" .env

# Sécuriser le fichier
chmod 600 .env

# Sauvegarder les credentials
CREDENTIALS_FILE="/root/inptic-credentials.txt"
cat > $CREDENTIALS_FILE << EOF
=== INPTIC Étudiants - Credentials ===
Date: $(date)

PostgreSQL:
  User: inptic_prod_user
  Password: $POSTGRES_PASSWORD
  Database: inptic_prod_db

Grafana:
  URL: http://$(hostname -I | awk '{print $1}'):3001
  Username: admin
  Password: $GRAFANA_PASSWORD

Jenkins:
  URL: http://$(hostname -I | awk '{print $1}'):8080/jenkins
  Username: admin
  Password: $JENKINS_PASSWORD

Flask Secret Key: $SECRET_KEY
JWT Secret: $JWT_SECRET

⚠️ IMPORTANT: Sauvegardez ce fichier en lieu sûr et supprimez-le du serveur !
EOF

chmod 600 $CREDENTIALS_FILE

log_success "Variables d'environnement configurées"
log_warning "Credentials sauvegardés dans : $CREDENTIALS_FILE"

# ============================================================
# Étape 8 : Démarrage des services
# ============================================================
log_info "Étape 8/10 : Construction et démarrage des services..."
log_warning "Cela peut prendre plusieurs minutes..."

cd $INSTALL_DIR
docker-compose build > /dev/null 2>&1
docker-compose up -d

# Attendre que les services démarrent
log_info "Attente du démarrage des services (30 secondes)..."
sleep 30

log_success "Services démarrés"

# ============================================================
# Étape 9 : Configuration des backups
# ============================================================
log_info "Étape 9/10 : Configuration des backups..."

mkdir -p /opt/backups/inptic
chmod +x $INSTALL_DIR/scripts/backup.sh

# Ajouter au crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $INSTALL_DIR/scripts/backup.sh") | crontab -

log_success "Backups automatiques configurés (2h du matin)"

# ============================================================
# Étape 10 : Configuration du service systemd
# ============================================================
log_info "Étape 10/10 : Configuration du service systemd..."

cat > /etc/systemd/system/inptic.service << EOF
[Unit]
Description=INPTIC Étudiants Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable inptic.service > /dev/null 2>&1

log_success "Service systemd configuré"

# ============================================================
# Vérification finale
# ============================================================
echo ""
log_info "=== Vérification de l'installation ==="
echo ""

# Vérifier les conteneurs
CONTAINERS=$(docker ps --format "{{.Names}}" | wc -l)
if [ $CONTAINERS -eq 7 ]; then
    log_success "Tous les conteneurs sont en cours d'exécution ($CONTAINERS/7)"
else
    log_warning "Seulement $CONTAINERS/7 conteneurs en cours d'exécution"
fi

# Tester les services
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
log_info "Test des services..."

# Flask
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    log_success "Flask App : OK"
else
    log_warning "Flask App : En attente..."
fi

# Grafana
if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
    log_success "Grafana : OK"
else
    log_warning "Grafana : En attente..."
fi

# Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    log_success "Prometheus : OK"
else
    log_warning "Prometheus : En attente..."
fi

# ============================================================
# Résumé final
# ============================================================
echo ""
echo "============================================================"
log_success "Installation terminée avec succès !"
echo "============================================================"
echo ""
echo "📊 Accès aux services :"
echo ""
echo "  🌐 Application Flask"
echo "     http://$SERVER_IP:5000"
echo ""
echo "  📈 Grafana"
echo "     http://$SERVER_IP:3001"
echo "     Username: admin"
echo "     Password: $GRAFANA_PASSWORD"
echo ""
echo "  🔧 Jenkins"
echo "     http://$SERVER_IP:8080/jenkins"
echo "     Username: admin"
echo "     Password: $JENKINS_PASSWORD"
echo ""
echo "  📊 Prometheus"
echo "     http://$SERVER_IP:9090"
echo ""
echo "  🚨 Alertmanager"
echo "     http://$SERVER_IP:9093"
echo ""
echo "============================================================"
echo ""
echo "📝 Credentials sauvegardés dans : $CREDENTIALS_FILE"
echo "⚠️  IMPORTANT : Sauvegardez ce fichier et supprimez-le du serveur !"
echo ""
echo "📚 Documentation :"
echo "   - Guide complet : $INSTALL_DIR/INSTALL-CENTOS.md"
echo "   - Production : $INSTALL_DIR/PRODUCTION.md"
echo "   - Dépannage : $INSTALL_DIR/TROUBLESHOOTING.md"
echo ""
echo "🔧 Commandes utiles :"
echo "   - Voir les services : docker-compose ps"
echo "   - Voir les logs : docker-compose logs -f"
echo "   - Redémarrer : docker-compose restart"
echo "   - Arrêter : docker-compose down"
echo ""
echo "💾 Backups automatiques : Tous les jours à 2h du matin"
echo "   Répertoire : /opt/backups/inptic/"
echo ""
log_success "🎉 INPTIC Étudiants est maintenant opérationnel !"
echo ""
