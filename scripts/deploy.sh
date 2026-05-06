#!/bin/bash

# Script de déploiement automatisé pour VM
# Usage: ./scripts/deploy.sh

set -e

echo "🚀 Déploiement de l'infrastructure INPTIC DevOps"
echo "================================================"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! docker compose version &> /dev/null; then
    log_error "Docker Compose n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

log_info "Docker et Docker Compose sont installés ✓"

# Vérifier si le fichier .env existe
if [ ! -f .env ]; then
    log_warn "Fichier .env non trouvé. Copie depuis .env.example..."
    cp .env.example .env
    log_warn "⚠️  IMPORTANT: Éditez le fichier .env avec vos valeurs avant de continuer!"
    log_warn "Appuyez sur Entrée après avoir configuré .env, ou Ctrl+C pour annuler"
    read -r
fi

# Vérifier les ports disponibles
log_info "Vérification des ports requis..."
PORTS=(5000 3000 8080 9090 9093 5432)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        log_warn "Le port $port est déjà utilisé"
    else
        log_info "Port $port disponible ✓"
    fi
done

# Arrêter les conteneurs existants
log_info "Arrêt des conteneurs existants (si présents)..."
docker compose down 2>/dev/null || true

# Construire les images
log_info "Construction des images Docker..."
docker compose build

# Démarrer les services
log_info "Démarrage des services..."
docker compose up -d

# Attendre que les services soient prêts
log_info "Attente du démarrage des services..."
sleep 10

# Vérifier l'état des conteneurs
log_info "Vérification de l'état des services..."
docker compose ps

# Afficher les URLs d'accès
echo ""
echo "================================================"
echo "✅ Déploiement terminé avec succès!"
echo "================================================"
echo ""
echo "Services accessibles sur:"
echo "  📱 Application Flask:  http://localhost:5000"
echo "  📊 Grafana:           http://localhost:3000 (admin/admin)"
echo "  🔧 Jenkins:           http://localhost:8080"
echo "  📈 Prometheus:        http://localhost:9090"
echo "  🔔 Alertmanager:      http://localhost:9093"
echo ""
echo "Commandes utiles:"
echo "  - Voir les logs:      docker compose logs -f"
echo "  - Arrêter:            docker compose down"
echo "  - Redémarrer:         docker compose restart"
echo ""
echo "Pour plus d'informations, consultez DEPLOYMENT.md"
echo "================================================"
