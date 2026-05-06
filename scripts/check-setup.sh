#!/bin/bash

# Script de vérification de la configuration complète
# Vérifie que tous les fichiers nécessaires sont présents

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Vérification de la Configuration INPTIC DevOps       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0
WARNINGS=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 ${RED}(MANQUANT)${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ ${RED}(MANQUANT)${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

check_optional() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${YELLOW}⚠${NC} $1 ${YELLOW}(optionnel)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[1] Fichiers principaux${NC}"
echo "─────────────────────────────────────────────────────"
check_file "docker-compose.yml"
check_file "Dockerfile"
check_file ".env.example"
check_file "Makefile"
check_file "README.md"

if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env"
else
    echo -e "${YELLOW}⚠${NC} .env ${YELLOW}(sera créé depuis .env.example)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[2] Application Flask${NC}"
echo "─────────────────────────────────────────────────────"
check_file "app/app.py"
check_file "app/config.py"
check_file "app/models.py"
check_file "app/metrics.py"
check_file "app/email_service.py"
check_file "app/requirements.txt"
check_dir "app/static"
check_file "app/static/index.html"
check_file "app/static/style.css"
check_file "app/static/app.js"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[3] Prometheus${NC}"
echo "─────────────────────────────────────────────────────"
check_dir "prometheus"
check_file "prometheus/prometheus.yml"
check_file "prometheus/alerts.yml"
check_file "prometheus/alertmanager.yml"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[4] Grafana${NC}"
echo "─────────────────────────────────────────────────────"
check_dir "grafana"
check_dir "grafana/datasources"
check_dir "grafana/dashboards"
check_dir "grafana/alerting"
check_dir "grafana/notifiers"
check_file "grafana/datasources/prometheus.yml"
check_file "grafana/dashboards/dashboard.yml"
check_file "grafana/dashboards/inptic-rh.json"
check_file "grafana/alerting/alerting.yml"
check_file "grafana/notifiers/notifiers.yml"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[5] Jenkins${NC}"
echo "─────────────────────────────────────────────────────"
check_dir "jenkins"
check_file "jenkins/Dockerfile"
check_file "jenkins/plugins.txt"
check_dir "jenkins/casc"
check_file "jenkins/casc/jenkins.yml"
check_file "jenkins/casc/jobs.yml"
check_file "jenkins/casc/credentials.yml"
check_file "Jenkinsfile"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[6] PostgreSQL${NC}"
echo "─────────────────────────────────────────────────────"
check_dir "postgres"
check_dir "postgres/init"
check_file "postgres/init/01_extensions.sql"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[7] Scripts${NC}"
echo "─────────────────────────────────────────────────────"
check_dir "scripts"
check_file "scripts/deploy.sh"
check_file "scripts/deploy-to-vm.sh"
check_file "scripts/init-alertmanager.sh"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[8] Documentation${NC}"
echo "─────────────────────────────────────────────────────"
check_file "README.md"
check_file "QUICKSTART.md"
check_file "DEPLOYMENT.md"
check_file "DEPLOY-QUICKSTART.md"

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[9] Vérification Docker${NC}"
echo "─────────────────────────────────────────────────────"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker installé ($(docker --version | cut -d' ' -f3 | tr -d ','))"
else
    echo -e "${RED}✗${NC} Docker non installé"
    ERRORS=$((ERRORS + 1))
fi

if docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker Compose installé ($(docker compose version | cut -d' ' -f4))"
else
    echo -e "${RED}✗${NC} Docker Compose non installé"
    ERRORS=$((ERRORS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}[10] Validation docker-compose.yml${NC}"
echo "─────────────────────────────────────────────────────"

if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    if docker compose config > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} docker-compose.yml est valide"
        
        # Compter les services
        SERVICES=$(docker compose config --services 2>/dev/null | wc -l)
        echo -e "${GREEN}✓${NC} $SERVICES services configurés:"
        docker compose config --services 2>/dev/null | while read service; do
            echo -e "  ${GREEN}•${NC} $service"
        done
    else
        echo -e "${RED}✗${NC} docker-compose.yml contient des erreurs"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} Impossible de valider (Docker non disponible)"
    WARNINGS=$((WARNINGS + 1))
fi

# ═══════════════════════════════════════════════════════
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Résumé de la Vérification                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "\n${GREEN}✅ Configuration complète et valide !${NC}"
    echo -e "${GREEN}   Tous les fichiers nécessaires sont présents.${NC}"
    echo ""
    echo -e "${BLUE}Prochaines étapes :${NC}"
    echo -e "  1. Configurez le fichier .env avec vos valeurs"
    echo -e "  2. Lancez : ${GREEN}make up${NC} ou ${GREEN}./scripts/deploy.sh${NC}"
    echo -e "  3. Accédez aux services sur les ports configurés"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "\n${YELLOW}⚠️  Configuration OK avec $WARNINGS avertissement(s)${NC}"
    echo -e "${YELLOW}   Vous pouvez continuer, mais vérifiez les fichiers optionnels.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ $ERRORS erreur(s) détectée(s)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS avertissement(s)${NC}"
    fi
    echo -e "\n${RED}Veuillez corriger les fichiers manquants avant de continuer.${NC}"
    exit 1
fi
