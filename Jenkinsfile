pipeline {
    agent any

    environment {
        APP_NAME       = 'inptic-etudiants'
        GIT_REPO       = 'https://github.com/Herlymba828/inptic-etudiants.git'
        DEPLOY_DIR     = '/opt/inptic-etudiants'
        APP_URL        = 'http://localhost:5000'
        GRAFANA_URL    = 'http://localhost:3001'
        PROMETHEUS_URL = 'http://localhost:9090'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    triggers {
        pollSCM('H/2 * * * *')
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
                    echo "   Branch  : $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
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
                    python3 -m py_compile app/app.py       && echo "✅ app.py OK"
                    python3 -m py_compile app/models.py    && echo "✅ models.py OK"
                    python3 -m py_compile app/email_service.py && echo "✅ email_service.py OK"
                    python3 -m py_compile app/metrics.py   && echo "✅ metrics.py OK"

                    echo ""
                    echo "=== Vérification Dockerfile ==="
                    test -f Dockerfile && echo "✅ Dockerfile présent"

                    echo ""
                    echo "=== Vérification fichiers statiques ==="
                    test -f app/static/index.html && echo "✅ index.html présent"
                    test -f app/static/app.js     && echo "✅ app.js présent"
                    test -f app/static/style.css  && echo "✅ style.css présent"

                    echo ""
                    echo "=== Vérification configs monitoring ==="
                    test -f prometheus/prometheus.yml              && echo "✅ prometheus.yml présent"
                    test -f grafana/datasources/prometheus.yml     && echo "✅ datasource Grafana présent"
                    test -f grafana/dashboards/inptic-rh.json      && echo "✅ Dashboard Grafana présent"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🧪 Tests Unitaires') {
            steps {
                echo '🧪 Exécution des tests...'
                sh '''
                    # Installer les dépendances dans un venv isolé
                    python3 -m venv /tmp/inptic_venv 2>/dev/null || true
                    /tmp/inptic_venv/bin/pip install -q -r app/requirements.txt

                    echo "=== Test 1 : Import des modules ==="
                    /tmp/inptic_venv/bin/python3 -c "
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
                    /tmp/inptic_venv/bin/python3 -c "
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

with app.test_client() as client:
    r = client.get('/api')
    assert r.status_code == 200, f'API: {r.status_code}'
    print('✅ Route /api accessible')

    r = client.get('/')
    assert r.status_code in [200, 404], f'Frontend: {r.status_code}'
    print('✅ Route / accessible')

print('✅ Tous les tests passent !')
"
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
                    docker images | grep ${APP_NAME} || true
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🚀 Déploiement') {
            steps {
                echo '🚀 Déploiement en production...'
                sh '''
                    echo "=== Pull des dernières modifications ==="
                    cd ${DEPLOY_DIR}
                    git pull origin main

                    echo ""
                    echo "=== Redémarrage du service Flask ==="
                    docker compose up -d --build app

                    echo ""
                    echo "=== Attente du démarrage (20s) ==="
                    sleep 20

                    echo ""
                    echo "=== État des conteneurs ==="
                    docker compose ps
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('🏥 Health Check') {
            steps {
                echo '🏥 Vérification post-déploiement...'
                sh '''
                    echo "=== Test Flask App ==="
                    HEALTH=$(curl -s --max-time 10 http://localhost:5000/health || echo "FAILED")
                    echo "Response: $HEALTH"
                    echo $HEALTH | grep -q "healthy" && echo "✅ Flask App OK" || (echo "❌ Flask App KO" && exit 1)

                    echo ""
                    echo "=== Test API Étudiants ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:5000/api/etudiants)
                    [ "$STATUS" = "200" ] && echo "✅ /api/etudiants OK" || (echo "❌ API KO: $STATUS" && exit 1)

                    echo ""
                    echo "=== Test API Stats ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:5000/api/stats)
                    [ "$STATUS" = "200" ] && echo "✅ /api/stats OK" || echo "⚠️ Stats: $STATUS"

                    echo ""
                    echo "=== Test Métriques ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:5000/metrics)
                    [ "$STATUS" = "200" ] && echo "✅ /metrics OK" || echo "⚠️ Metrics: $STATUS"

                    echo ""
                    echo "=== Test Prometheus ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:9090/-/healthy)
                    [ "$STATUS" = "200" ] && echo "✅ Prometheus OK" || echo "⚠️ Prometheus: $STATUS"

                    echo ""
                    echo "=== Test Grafana ==="
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3001/api/health)
                    [ "$STATUS" = "200" ] && echo "✅ Grafana OK" || echo "⚠️ Grafana: $STATUS"

                    echo ""
                    echo "=== État des conteneurs ==="
                    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|flask|postgres|prometheus|grafana|jenkins|alertmanager|postfix"
                '''
            }
        }

        // ─────────────────────────────────────────────────────────
        stage('📊 Rapport') {
            steps {
                sh '''
                    COMMIT=$(git rev-parse --short HEAD)
                    DATE=$(date "+%d/%m/%Y %H:%M:%S")
                    ETUDIANTS=$(curl -s --max-time 5 http://localhost:5000/api/stats | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_etudiants','N/A'))" 2>/dev/null || echo "N/A")

                    echo ""
                    echo "╔══════════════════════════════════════════════════════╗"
                    echo "║         RAPPORT DE DÉPLOIEMENT INPTIC RH            ║"
                    echo "╠══════════════════════════════════════════════════════╣"
                    printf "║  Build     : #%-38s║\n" "${BUILD_NUMBER}"
                    printf "║  Commit    : %-38s║\n" "${COMMIT}"
                    printf "║  Date      : %-38s║\n" "${DATE}"
                    printf "║  Étudiants : %-38s║\n" "${ETUDIANTS}"
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
        }
        always {
            echo '🧹 Nettoyage...'
            cleanWs()
        }
    }
}
