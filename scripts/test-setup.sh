#!/bin/bash

# Script de test complet de l'infrastructure INPTIC DevOps
# Vérifie la configuration et teste tous les services

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Test Complet - Infrastructure INPTIC DevOps       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════
echo -e "${CYAN}[1/8] Vérification de Docker${NC}"
echo "─────────────────────────────────────────────────────"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker n'est pas installé${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Docker installé${NC}"
    
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓ Docker daemon en cours d'exécution${NC}"
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        echo -e "  Version: ${DOCKER_VERSION}"
    else
        echo -e "${RED}✗ Docker daemon n'est pas démarré${NC}"
        echo -e "${YELLOW}  → Démarrez Docker Desktop${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

if docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker Compose installé${NC}"
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "  Version: ${COMPOSE_VERSION}"
else
    echo -e "${RED}✗ Docker Compose n'est pas installé${NC}"
    ERRORS=$((ERRORS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[2/8] Validation docker-compose.yml${NC}"
echo "─────────────────────────────────────────────────────"

if docker compose config --quiet 2>&1; then
    echo -e "${GREEN}✓ docker-compose.yml est valide${NC}"
    
    SERVICES=$(docker compose config --services 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ ${SERVICES} services configurés:${NC}"
    docker compose config --services 2>/dev/null | while read service; do
        echo -e "  ${GREEN}•${NC} $service"
    done
else
    echo -e "${RED}✗ docker-compose.yml contient des erreurs${NC}"
    ERRORS=$((ERRORS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[3/8] Vérification du fichier .env${NC}"
echo "─────────────────────────────────────────────────────"

if [ ! -f .env ]; then
    echo -e "${RED}✗ Fichier .env manquant${NC}"
    echo -e "${YELLOW}  → Copiez .env.example vers .env${NC}"
    echo -e "${YELLOW}  → Commande: cp .env.example .env${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Fichier .env présent${NC}"
    
    # Vérifier les variables critiques
    CRITICAL_VARS=(
        "POSTGRES_PASSWORD"
        "SECRET_KEY"
        "SMTP_PASSWORD"
        "GRAFANA_ADMIN_PASSWORD"
        "JENKINS_ADMIN_PASSWORD"
    )
    
    for var in "${CRITICAL_VARS[@]}"; do
        if grep -q "^${var}=changeme" .env 2>/dev/null; then
            echo -e "${YELLOW}⚠ ${var} utilise une valeur par défaut${NC}"
            WARNINGS=$((WARNINGS + 1))
        elif grep -q "^${var}=" .env 2>/dev/null; then
            echo -e "${GREEN}✓ ${var} configuré${NC}"
        else
            echo -e "${RED}✗ ${var} manquant${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[4/8] Vérification des ports disponibles${NC}"
echo "─────────────────────────────────────────────────────"

PORTS=(5000 3000 8080 9090 9093 5432 9187)
PORT_NAMES=("Flask" "Grafana" "Jenkins" "Prometheus" "Alertmanager" "PostgreSQL" "Postgres Exporter")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    
    if netstat -ano | grep -q ":${PORT}.*LISTENING" 2>/dev/null || \
       lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Port ${PORT} (${NAME}) déjà utilisé${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ Port ${PORT} (${NAME}) disponible${NC}"
    fi
done

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[5/8] Vérification des fichiers de configuration${NC}"
echo "─────────────────────────────────────────────────────"

CONFIG_FILES=(
    "prometheus/prometheus.yml"
    "prometheus/alerts.yml"
    "prometheus/alertmanager.yml"
    "grafana/datasources/prometheus.yml"
    "grafana/dashboards/dashboard.yml"
    "jenkins/Dockerfile"
    "jenkins/plugins.txt"
    "jenkins/casc/jenkins.yml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file ${RED}(MANQUANT)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[6/8] Test de build des images${NC}"
echo "─────────────────────────────────────────────────────"

if docker info &> /dev/null; then
    echo -e "${BLUE}Building images (cela peut prendre quelques minutes)...${NC}"
    
    if docker compose build --quiet 2>&1 | tee /tmp/build.log; then
        echo -e "${GREEN}✓ Toutes les images ont été construites avec succès${NC}"
    else
        echo -e "${RED}✗ Erreur lors du build des images${NC}"
        echo -e "${YELLOW}Voir les logs ci-dessus pour plus de détails${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠ Docker non disponible, build ignoré${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[7/8] Vérification de l'espace disque${NC}"
echo "─────────────────────────────────────────────────────"

if command -v df &> /dev/null; then
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | tr -d '%')
    DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')
    
    if [ "$DISK_USAGE" -lt 80 ]; then
        echo -e "${GREEN}✓ Espace disque suffisant${NC}"
        echo -e "  Disponible: ${DISK_AVAIL}"
    else
        echo -e "${YELLOW}⚠ Espace disque faible (${DISK_USAGE}% utilisé)${NC}"
        echo -e "  Disponible: ${DISK_AVAIL}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ Impossible de vérifier l'espace disque${NC}"
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${CYAN}[8/8] État des conteneurs (si démarrés)${NC}"
echo "─────────────────────────────────────────────────────"

if docker compose ps 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✓ Des conteneurs sont en cours d'exécution:${NC}"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
else
    echo -e "${YELLOW}ℹ Aucun conteneur en cours d'exécution${NC}"
    echo -e "  Utilisez 'make up' ou 'docker compose up -d' pour démarrer"
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Résumé du Test                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "\n${GREEN}✅ Tous les tests sont passés !${NC}"
    echo -e "${GREEN}   L'infrastructure est prête à être démarrée.${NC}"
    echo ""
    echo -e "${BLUE}Prochaines étapes :${NC}"
    echo -e "  1. Vérifiez/modifiez le fichier .env si nécessaire"
    echo -e "  2. Démarrez les services : ${GREEN}make up${NC}"
    echo -e "  3. Vérifiez l'état : ${GREEN}make status${NC}"
    echo -e "  4. Accédez aux services :"
    echo -e "     • Application : ${CYAN}http://localhost:5000${NC}"
    echo -e "     • Grafana     : ${CYAN}http://localhost:3000${NC}"
    echo -e "     • Jenkins     : ${CYAN}http://localhost:8080${NC}"
    echo -e "     • Prometheus  : ${CYAN}http://localhost:9090${NC}"
    exit 0
    
elif [ $ERRORS -eq 0 ]; then
    echo -e "\n${YELLOW}⚠️  Tests OK avec ${WARNINGS} avertissement(s)${NC}"
    echo -e "${YELLOW}   Vous pouvez continuer mais vérifiez les avertissements.${NC}"
    echo ""
    echo -e "${BLUE}Pour démarrer :${NC}"
    echo -e "  ${GREEN}make up${NC}"
    exit 0
    
else
    echo -e "\n${RED}❌ ${ERRORS} erreur(s) détectée(s)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  ${WARNINGS} avertissement(s)${NC}"
    fi
    echo ""
    echo -e "${RED}Veuillez corriger les erreurs avant de continuer.${NC}"
    echo ""
    echo -e "${BLUE}Actions recommandées :${NC}"
    
    if ! docker info &> /dev/null; then
        echo -e "  1. ${YELLOW}Démarrez Docker Desktop${NC}"
    fi
    
    if [ ! -f .env ]; then
        echo -e "  2. ${YELLOW}Créez le fichier .env : cp .env.example .env${NC}"
    fi
    
    echo -e "  3. ${YELLOW}Relancez ce script : ./scripts/test-setup.sh${NC}"
    exit 1
fi
