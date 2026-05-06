#!/bin/bash

# Script pour déployer sur une VM distante
# Usage: ./scripts/deploy-to-vm.sh user@vm-ip

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les arguments
if [ $# -eq 0 ]; then
    log_error "Usage: $0 user@vm-ip"
    log_error "Exemple: $0 ubuntu@192.168.1.100"
    exit 1
fi

VM_HOST=$1
PROJECT_NAME="inptic-etudiants"
REMOTE_DIR="/home/$(echo $VM_HOST | cut -d'@' -f1)/$PROJECT_NAME"

log_info "🚀 Déploiement vers $VM_HOST"
echo "================================================"

# Vérifier la connexion SSH
log_info "Vérification de la connexion SSH..."
if ! ssh -o ConnectTimeout=5 $VM_HOST "echo 'Connexion OK'" &> /dev/null; then
    log_error "Impossible de se connecter à $VM_HOST"
    log_error "Vérifiez que:"
    log_error "  1. La VM est accessible"
    log_error "  2. Vous avez configuré l'authentification SSH"
    log_error "  3. L'adresse IP est correcte"
    exit 1
fi
log_info "Connexion SSH établie ✓"

# Vérifier si Git est installé sur la VM
log_info "Vérification de Git sur la VM..."
if ! ssh $VM_HOST "command -v git" &> /dev/null; then
    log_warn "Git n'est pas installé sur la VM. Installation..."
    ssh $VM_HOST "sudo apt update && sudo apt install -y git"
fi

# Vérifier si Docker est installé sur la VM
log_info "Vérification de Docker sur la VM..."
if ! ssh $VM_HOST "command -v docker" &> /dev/null; then
    log_warn "Docker n'est pas installé. Installation..."
    ssh $VM_HOST "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker \$USER"
    log_warn "⚠️  Vous devrez peut-être vous reconnecter à la VM pour que Docker fonctionne"
fi

# Vérifier si Docker Compose est installé
log_info "Vérification de Docker Compose sur la VM..."
if ! ssh $VM_HOST "docker compose version" &> /dev/null; then
    log_warn "Docker Compose n'est pas installé. Installation..."
    ssh $VM_HOST "sudo apt update && sudo apt install -y docker-compose-plugin"
fi

# Cloner ou mettre à jour le dépôt
log_info "Déploiement du code..."
ssh $VM_HOST << 'ENDSSH'
set -e

PROJECT_NAME="inptic-etudiants"
REMOTE_DIR="$HOME/$PROJECT_NAME"
REPO_URL="https://github.com/Herlymba828/inptic-etudiants.git"

if [ -d "$REMOTE_DIR" ]; then
    echo "Mise à jour du dépôt existant..."
    cd $REMOTE_DIR
    git pull origin main
else
    echo "Clonage du dépôt..."
    git clone $REPO_URL $REMOTE_DIR
    cd $REMOTE_DIR
fi

# Copier .env.example vers .env si nécessaire
if [ ! -f .env ]; then
    echo "Création du fichier .env..."
    cp .env.example .env
    echo "⚠️  N'oubliez pas de configurer le fichier .env!"
fi

# Rendre les scripts exécutables
chmod +x scripts/*.sh

echo "Code déployé dans: $REMOTE_DIR"
ENDSSH

log_info "Code déployé avec succès ✓"

# Demander si on doit démarrer les services
echo ""
read -p "Voulez-vous démarrer les services Docker maintenant? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Démarrage des services Docker..."
    ssh $VM_HOST "cd $REMOTE_DIR && docker compose up -d"
    
    log_info "Attente du démarrage des services..."
    sleep 10
    
    # Récupérer l'IP de la VM
    VM_IP=$(echo $VM_HOST | cut -d'@' -f2)
    
    echo ""
    echo "================================================"
    echo "✅ Déploiement terminé avec succès!"
    echo "================================================"
    echo ""
    echo "Services accessibles sur:"
    echo "  📱 Application Flask:  http://$VM_IP:5000"
    echo "  📊 Grafana:           http://$VM_IP:3000"
    echo "  🔧 Jenkins:           http://$VM_IP:8080"
    echo "  📈 Prometheus:        http://$VM_IP:9090"
    echo "  🔔 Alertmanager:      http://$VM_IP:9093"
    echo ""
    echo "Pour voir les logs:"
    echo "  ssh $VM_HOST 'cd $REMOTE_DIR && docker compose logs -f'"
    echo ""
    echo "Pour vous connecter à la VM:"
    echo "  ssh $VM_HOST"
    echo "================================================"
else
    log_info "Services non démarrés. Pour les démarrer manuellement:"
    echo "  ssh $VM_HOST"
    echo "  cd $REMOTE_DIR"
    echo "  docker compose up -d"
fi

echo ""
log_info "Pour plus d'informations, consultez DEPLOYMENT.md"
