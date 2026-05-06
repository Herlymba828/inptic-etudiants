# Script de test complet de l'infrastructure INPTIC DevOps (Windows PowerShell)
# Vérifie la configuration et teste tous les services

$ErrorActionPreference = "Continue"

$ERRORS = 0
$WARNINGS = 0

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-Host ""
Write-ColorOutput Cyan "╔════════════════════════════════════════════════════════╗"
Write-ColorOutput Cyan "║     Test Complet - Infrastructure INPTIC DevOps       ║"
Write-ColorOutput Cyan "╚════════════════════════════════════════════════════════╝"
Write-Host ""

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[1/8] Vérification de Docker"
Write-Host "─────────────────────────────────────────────────────"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-ColorOutput Green "✓ Docker installé"
    
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✓ Docker daemon en cours d'exécution"
        $dockerVersion = (docker --version).Split(" ")[2].TrimEnd(",")
        Write-Host "  Version: $dockerVersion"
    } else {
        Write-ColorOutput Red "✗ Docker daemon n'est pas démarré"
        Write-ColorOutput Yellow "  → Démarrez Docker Desktop"
        $ERRORS++
    }
} else {
    Write-ColorOutput Red "✗ Docker n'est pas installé"
    $ERRORS++
}

$composeCheck = docker compose version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Green "✓ Docker Compose installé"
    $composeVersion = ($composeCheck | Select-String "version").ToString().Split(" ")[-1]
    Write-Host "  Version: $composeVersion"
} else {
    Write-ColorOutput Red "✗ Docker Compose n'est pas installé"
    $ERRORS++
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[2/8] Validation docker-compose.yml"
Write-Host "─────────────────────────────────────────────────────"

$configCheck = docker compose config --quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Green "✓ docker-compose.yml est valide"
    
    $services = docker compose config --services 2>$null
    $serviceCount = ($services | Measure-Object).Count
    Write-ColorOutput Green "✓ $serviceCount services configurés:"
    foreach ($service in $services) {
        Write-Host "  • $service" -ForegroundColor Green
    }
} else {
    Write-ColorOutput Red "✗ docker-compose.yml contient des erreurs"
    $ERRORS++
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[3/8] Vérification du fichier .env"
Write-Host "─────────────────────────────────────────────────────"

if (Test-Path .env) {
    Write-ColorOutput Green "✓ Fichier .env présent"
    
    $criticalVars = @(
        "POSTGRES_PASSWORD",
        "SECRET_KEY",
        "SMTP_PASSWORD",
        "GRAFANA_ADMIN_PASSWORD",
        "JENKINS_ADMIN_PASSWORD"
    )
    
    $envContent = Get-Content .env -Raw
    
    foreach ($var in $criticalVars) {
        if ($envContent -match "$var=changeme") {
            Write-ColorOutput Yellow "⚠ $var utilise une valeur par défaut"
            $WARNINGS++
        } elseif ($envContent -match "$var=") {
            Write-ColorOutput Green "✓ $var configuré"
        } else {
            Write-ColorOutput Red "✗ $var manquant"
            $ERRORS++
        }
    }
} else {
    Write-ColorOutput Red "✗ Fichier .env manquant"
    Write-ColorOutput Yellow "  → Copiez .env.example vers .env"
    Write-ColorOutput Yellow "  → Commande: cp .env.example .env"
    $ERRORS++
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[4/8] Vérification des ports disponibles"
Write-Host "─────────────────────────────────────────────────────"

$ports = @{
    5000 = "Flask"
    3000 = "Grafana"
    8080 = "Jenkins"
    9090 = "Prometheus"
    9093 = "Alertmanager"
    5432 = "PostgreSQL"
    9187 = "Postgres Exporter"
}

foreach ($port in $ports.Keys) {
    $name = $ports[$port]
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    
    if ($connection) {
        Write-ColorOutput Yellow "⚠ Port $port ($name) déjà utilisé"
        $WARNINGS++
    } else {
        Write-ColorOutput Green "✓ Port $port ($name) disponible"
    }
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[5/8] Vérification des fichiers de configuration"
Write-Host "─────────────────────────────────────────────────────"

$configFiles = @(
    "prometheus/prometheus.yml",
    "prometheus/alerts.yml",
    "prometheus/alertmanager.yml",
    "grafana/datasources/prometheus.yml",
    "grafana/dashboards/dashboard.yml",
    "jenkins/Dockerfile",
    "jenkins/plugins.txt",
    "jenkins/casc/jenkins.yml"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-ColorOutput Green "✓ $file"
    } else {
        Write-ColorOutput Red "✗ $file (MANQUANT)"
        $ERRORS++
    }
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[6/8] Test de build des images"
Write-Host "─────────────────────────────────────────────────────"

$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput Blue "Building images (cela peut prendre quelques minutes)..."
    
    $buildOutput = docker compose build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✓ Toutes les images ont été construites avec succès"
    } else {
        Write-ColorOutput Red "✗ Erreur lors du build des images"
        Write-ColorOutput Yellow "Voir les logs ci-dessus pour plus de détails"
        $ERRORS++
    }
} else {
    Write-ColorOutput Yellow "⚠ Docker non disponible, build ignoré"
    $WARNINGS++
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[7/8] Vérification de l'espace disque"
Write-Host "─────────────────────────────────────────────────────"

$drive = (Get-Location).Drive
$driveInfo = Get-PSDrive $drive.Name
$freeSpaceGB = [math]::Round($driveInfo.Free / 1GB, 2)
$usedSpaceGB = [math]::Round($driveInfo.Used / 1GB, 2)
$totalSpaceGB = [math]::Round(($driveInfo.Used + $driveInfo.Free) / 1GB, 2)
$usedPercent = [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 0)

if ($usedPercent -lt 80) {
    Write-ColorOutput Green "✓ Espace disque suffisant"
    Write-Host "  Disponible: $freeSpaceGB GB / $totalSpaceGB GB"
} else {
    Write-ColorOutput Yellow "⚠ Espace disque faible ($usedPercent% utilisé)"
    Write-Host "  Disponible: $freeSpaceGB GB / $totalSpaceGB GB"
    $WARNINGS++
}

# ═══════════════════════════════════════════════════════
Write-ColorOutput Cyan "`n[8/8] État des conteneurs (si démarrés)"
Write-Host "─────────────────────────────────────────────────────"

$psOutput = docker compose ps 2>$null
if ($psOutput -match "Up") {
    Write-ColorOutput Green "✓ Des conteneurs sont en cours d'exécution:"
    docker compose ps
} else {
    Write-ColorOutput Yellow "ℹ Aucun conteneur en cours d'exécution"
    Write-Host "  Utilisez 'make up' ou 'docker compose up -d' pour démarrer"
}

# ═══════════════════════════════════════════════════════
Write-Host ""
Write-ColorOutput Cyan "╔════════════════════════════════════════════════════════╗"
Write-ColorOutput Cyan "║                  Résumé du Test                        ║"
Write-ColorOutput Cyan "╚════════════════════════════════════════════════════════╝"

if ($ERRORS -eq 0 -and $WARNINGS -eq 0) {
    Write-Host ""
    Write-ColorOutput Green "✅ Tous les tests sont passés !"
    Write-ColorOutput Green "   L'infrastructure est prête à être démarrée."
    Write-Host ""
    Write-ColorOutput Blue "Prochaines étapes :"
    Write-Host "  1. Vérifiez/modifiez le fichier .env si nécessaire"
    Write-ColorOutput Green "  2. Démarrez les services : make up"
    Write-ColorOutput Green "  3. Vérifiez l'état : make status"
    Write-Host "  4. Accédez aux services :"
    Write-ColorOutput Cyan "     • Application : http://localhost:5000"
    Write-ColorOutput Cyan "     • Grafana     : http://localhost:3000"
    Write-ColorOutput Cyan "     • Jenkins     : http://localhost:8080"
    Write-ColorOutput Cyan "     • Prometheus  : http://localhost:9090"
    exit 0
    
} elseif ($ERRORS -eq 0) {
    Write-Host ""
    Write-ColorOutput Yellow "⚠️  Tests OK avec $WARNINGS avertissement(s)"
    Write-ColorOutput Yellow "   Vous pouvez continuer mais vérifiez les avertissements."
    Write-Host ""
    Write-ColorOutput Blue "Pour démarrer :"
    Write-ColorOutput Green "  make up"
    exit 0
    
} else {
    Write-Host ""
    Write-ColorOutput Red "❌ $ERRORS erreur(s) détectée(s)"
    if ($WARNINGS -gt 0) {
        Write-ColorOutput Yellow "⚠️  $WARNINGS avertissement(s)"
    }
    Write-Host ""
    Write-ColorOutput Red "Veuillez corriger les erreurs avant de continuer."
    Write-Host ""
    Write-ColorOutput Blue "Actions recommandées :"
    
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Yellow "  1. Démarrez Docker Desktop"
    }
    
    if (-not (Test-Path .env)) {
        Write-ColorOutput Yellow "  2. Créez le fichier .env : cp .env.example .env"
    }
    
    Write-ColorOutput Yellow "  3. Relancez ce script : .\scripts\test-setup.ps1"
    exit 1
}
