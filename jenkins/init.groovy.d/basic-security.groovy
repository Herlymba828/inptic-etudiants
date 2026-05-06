// Script Groovy d'initialisation Jenkins
// Exécuté automatiquement au premier démarrage

import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

// Configurer la sécurité
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'JenkinsInptic2024'
hudsonRealm.createAccount('admin', adminPassword)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Marquer l'installation comme complète
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

instance.save()
println "✅ Jenkins initialisé avec succès"
println "   User: admin"
println "   Pass: ${adminPassword}"
