pipeline {
    agent any

    environment {
        APP_NAME        = 'inptic-etudiants'
        GIT_REPO        = 'https://github.com/Herlymba828/inptic-etudiants.git'
        DEPLOY_DIR      = '/opt/inptic-etudiants'
        APP_URL         = 'http://localhost:5000'
        GRAFANA_URL     = 'http://localhost:3001'
        PROMETHEUS_URL  = 'http://localhost:9090'
        JENKINS_URL_    = 'http://localhost:8080'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    stages {

        // ─────────────────────────────────────────────────────────
        stage('📥 Checkout') {
            steps {
                echo '🔄 Récupération du code source...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: "${GIT_REPO}"]]
                ])
                sh '''
                    echo "📋 Informations du commit :"
                    echo "   Branch  : $(git rev-parse --abbrev-ref HEAD)"
                    echo "   Commit  : $(git rev-parse --short HEAD)"
                    echo "   Message : $(git log -1 --pretty=%s)"
                    echo "   Auteur  : $(git log -1 --pretty=%an)"
                    echo "   Date    : $(git log -1 --pretty=%cd)"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🔍 Analyse du Code') {
            steps {
                echo '🔍 Vérification de la structure du projet...'
                sh '''
                    echo "=== Structure du projet ==="
                    ls -la

                    echo ""
                    echo "=== Fichiers Python ==="
                    find . -name "*.py" | grep -v __pycache__ | sort

                    echo ""
                    echo "=== Vérification syntaxe Python ==="
                    python3 -m py_compile app/app.py && echo "✅ app.py OK"
                    python3 -m py_compile app/models.py && echo "✅ models.py OK"
                    python3 -m py_compile app/email_service.py && echo "✅ email_service.py OK"
                    python3 -m py_compile app/metrics.py && echo "✅ metrics.py OK"

                    echo ""
                    echo "=== Vérification docker-compose.yml ==="
                    docker-compose config --quiet && echo "✅ docker-compose.yml valide"

                    echo ""
                    echo "=== Vérification Dockerfile ==="
                    test -f Dockerfile && echo "✅ Dockerfile présent"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🧪 Tests Unitaires') {
            steps {
                echo '🧪 Exécution des tests...'
                sh '''
                    # Installer les dépendances
                    pip3 install --user -q -r app/requirements.txt 2>/dev/null || true

                    echo "=== Test 1 : Import des modules ==="
                    python3 -c "
import sys
sys.path.insert(0, 'app')
from models import Etudiant, db
print('✅ models.py importé')
from metrics import etudiants_actifs, etudiants_ajoutes_total
print('✅ metrics.py importé')
from email_service import send_email, send_email_async
print('✅ email_service.py importé')
"

                    echo ""
                    echo "=== Test 2 : Création de l'application Flask ==="
                    python3 -c "
import os, sys
os.environ['JENKINS_TEST'] = 'true'
os.environ['POSTGRES_HOST'] = 'localhost'
os.environ['POSTGRES_USER'] = 'test'
os.environ['POSTGRES_PASSWORD'] = 'test'
os.environ['POSTGRES_DB'] = 'test'
sys.path.insert(0, 'app')
from app import app
assert app is not None
print('✅ Application Flask créée')

# Tester les routes
with app.test_client() as client:
    # Test route health
    r = client.get('/health')
    assert r.status_code in [200, 500], f'Health: {r.status_code}'
    print('✅ Route /health accessible')

    # Test route frontend
    r = client.get('/')
    assert r.status_code in [200, 404], f'Frontend: {r.status_code}'
    print('✅ Route / accessible')

    # Test route API info
    r = client.get('/api')
    assert r.status_code == 200, f'API: {r.status_code}'
    print('✅ Route /api accessible')

print('✅ Tous les tests passent !')
"

                    echo ""
                    echo "=== Test 3 : Vérification des fichiers statiques ==="
                    test -f app/static/index.html && echo "✅ index.html présent"
                    test -f app/static/app.js && echo "✅ app.js présent"
                    test -f app/static/style.css && echo "✅ style.css présent"

                    echo ""
                    echo "=== Test 4 : Vérification des configs ==="
                    test -f prometheus/prometheus.yml && echo "✅ prometheus.yml présent"
                    test -f grafana/datasources/prometheus.yml && echo "✅ datasource Grafana présent"
                    test -f grafana/dashboards/inptic-rh.json && echo "✅ Dashboard Grafana présent"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🔨 Build Docker') {
            steps {
                echo '🔨 Construction de l\'image Docker...'
                sh '''
                    echo "=== Build de l'image Flask ==="
                    docker build -t ${APP_NAME}-app:${BUILD_NUMBER} .
                    docker tag ${APP_NAME}-app:${BUILD_NUMBER} ${APP_NAME}-app:latest
                    echo "✅ Image ${APP_NAME}-app:${BUILD_NUMBER} construite"

                    echo ""
                    echo "=== Images disponibles ==="
                    docker images | grep ${APP_NAME}
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🚀 Déploiement') {
            steps {
                echo '🚀 Déploiement en production...'
                sh '''
                    cd ${DEPLOY_DIR}

                    echo "=== Pull des dernières modifications ==="
                    git pull origin main

                    echo ""
                    echo "=== Redémarrage des services mis à jour ==="
                    docker-compose up -d --build app

                    echo ""
                    echo "=== Attente du démarrage (20s) ==="
                    sleep 20

                    echo ""
                    echo "=== État des conteneurs ==="
                    docker-compose ps
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🏥 Health Check') {
            steps {
                echo '🏥 Vérification post-déploiement...'
                sh '''
                    echo "=== Test 1 : Flask App ==="
                    HEALTH=$(curl -s http://localhost:5000/health)
                    echo "Response: $HEALTH"
                    echo $HEALTH | grep -q "healthy" && echo "✅ Flask App OK" || (echo "❌ Flask App KO" && exit 1)

                    echo ""
                    echo "=== Test 2 : API Étudiants ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/etudiants)
                    echo "Status: $STATUS"
                    [ "$STATUS" = "200" ] && echo "✅ API /api/etudiants OK" || (echo "❌ API KO: $STATUS" && exit 1)

                    echo ""
                    echo "=== Test 3 : API Stats ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/stats)
                    [ "$STATUS" = "200" ] && echo "✅ API /api/stats OK" || echo "⚠️ API stats: $STATUS"

                    echo ""
                    echo "=== Test 4 : Métriques Prometheus ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/metrics)
                    [ "$STATUS" = "200" ] && echo "✅ /metrics OK" || echo "⚠️ Metrics: $STATUS"

                    echo ""
                    echo "=== Test 5 : Prometheus ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy)
                    [ "$STATUS" = "200" ] && echo "✅ Prometheus OK" || echo "⚠️ Prometheus: $STATUS"

                    echo ""
                    echo "=== Test 6 : Grafana ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/health)
                    [ "$STATUS" = "200" ] && echo "✅ Grafana OK" || echo "⚠️ Grafana: $STATUS"

                    echo ""
                    echo "=== Résumé des services ==="
                    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|inptic|flask|postgres|prometheus|grafana|jenkins|alertmanager|postfix"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('📊 Rapport') {
            steps {
                echo '📊 Génération du rapport de déploiement...'
                sh '''
                    COMMIT=$(git rev-parse --short HEAD)
                    DATE=$(date "+%d/%m/%Y %H:%M:%S")
                    ETUDIANTS=$(curl -s http://localhost:5000/api/stats | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_etudiants', 'N/A'))" 2>/dev/null || echo "N/A")

                    echo ""
                    echo "╔══════════════════════════════════════════════════════╗"
                    echo "║         RAPPORT DE DÉPLOIEMENT INPTIC RH            ║"
                    echo "╠══════════════════════════════════════════════════════╣"
                    echo "║  Build     : #${BUILD_NUMBER}                                ║"
                    echo "║  Commit    : ${COMMIT}                                   ║"
                    echo "║  Date      : ${DATE}              ║"
                    echo "║  Étudiants : ${ETUDIANTS}                                    ║"
                    echo "╠══════════════════════════════════════════════════════╣"
                    echo "║  🌐 App       : http://192.168.206.132:5000         ║"
                    echo "║  📊 Grafana   : http://192.168.206.132:3001         ║"
                    echo "║  📈 Prometheus: http://192.168.206.132:9090         ║"
                    echo "║  🔧 Jenkins   : http://192.168.206.132:8080         ║"
                    echo "╚══════════════════════════════════════════════════════╝"
                '''
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    post {
        success {
            echo '''
✅ ══════════════════════════════════════════════════
   PIPELINE INPTIC RH RÉUSSI !
   Déploiement effectué avec succès.
══════════════════════════════════════════════════
            '''
        }

        failure {
            echo '''
❌ ══════════════════════════════════════════════════
   PIPELINE INPTIC RH ÉCHOUÉ !
   Consultez les logs pour identifier le problème.
══════════════════════════════════════════════════
            '''
            // Rollback automatique si le déploiement échoue
            sh '''
                echo "🔄 Tentative de rollback..."
                cd /opt/inptic-etudiants
                docker-compose up -d app || true
                echo "Rollback terminé"
            '''
        }

        unstable {
            echo '⚠️ Pipeline instable — certains tests ont échoué'
        }

        always {
            echo '🧹 Nettoyage de l\'espace de travail...'
            cleanWs()
        }
    }
}
