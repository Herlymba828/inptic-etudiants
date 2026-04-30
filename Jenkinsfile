pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'inptic-rh-app'
        COMPOSE_PROJECT = 'inptic'
        JENKINS_TEST = 'true'
    }
    
    stages {
        stage('📥 Checkout') {
            steps {
                echo 'Clonage du dépôt...'
                git branch: 'main', 
                    url: 'https://github.com/votre-org/inptic-rh.git'
            }
        }
        
        stage('🔍 Vérification Code') {
            steps {
                echo 'Vérification du projet...'
                sh '''
                    echo "=== Fichiers du projet ==="
                    ls -la
                    echo ""
                    echo "=== Structure ==="
                    find . -type f -name "*.py" | head -20
                '''
            }
        }
        
        stage('🧪 Tests Unitaires') {
            steps {
                echo 'Tests de l\\'application RH...'
                sh '''
                    # Installer les dépendances
                    pip3 install --user -r app/requirements.txt 2>/dev/null || true
                    
                    # Test d'import
                    python3 -c "
import sys
sys.path.insert(0, 'app')
from models import Etudiant
print('✅ Modèle OK')
"
                    
                    # Test de création d'application
                    python3 -c "
import os
os.environ['JENKINS_TEST'] = 'true'
os.environ['POSTGRES_HOST'] = 'localhost'
import sys
sys.path.insert(0, 'app')
from app import app
print('✅ Application OK')
"
                '''
            }
        }
        
        stage('🔨 Build Docker') {
            steps {
                echo 'Construction de l\\'image Docker...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                    echo "✅ Image construite"
                '''
            }
        }
        
        stage('🚀 Déploiement') {
            steps {
                echo 'Déploiement en production...'
                sh '''
                    # Arrêter les anciens conteneurs
                    docker-compose down --remove-orphans || true
                    
                    # Démarrer avec la nouvelle version
                    docker-compose up -d --build
                    
                    # Attendre le démarrage
                    sleep 15
                    
                    # Vérifier
                    docker-compose ps
                '''
            }
        }
        
        stage('🏥 Health Check') {
            steps {
                echo 'Vérification post-déploiement...'
                sh '''
                    # Test API
                    echo "Test /health..."
                    curl -f http://localhost:5000/health || exit 1
                    
                    echo "Test /api/employes..."
                    curl -f http://localhost:5000/api/employes || exit 1
                    
                    echo "Test /metrics..."
                    curl -f http://localhost:5000/metrics | head -5
                    
                    echo ""
                    echo "✅ Tous les tests passent !"
                '''
            }
        }
    }
    
    post {
        success {
            echo '''
            ╔══════════════════════════════════════════════╗
            ║   ✅ PIPELINE INPTIC RH RÉUSSI !           ║
            ╠══════════════════════════════════════════════╣
            ║  API        : http://localhost:5000         ║
            ║  Prometheus : http://localhost:9090         ║
            ║  Grafana    : http://localhost:3000         ║
            ╚══════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '❌ PIPELINE ÉCHOUÉ - Vérifiez les logs ci-dessus'
        }
        always {
            cleanWs()
        }
    }
}
