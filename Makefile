# ============================================================
# INPTIC RH — Makefile
# Commandes pour gérer l'ensemble de la stack
# ============================================================

.PHONY: help up down restart build logs ps clean backup restore \
        jenkins-url grafana-url prometheus-url reload-prometheus \
        webhook-setup status

# Couleurs
GREEN  := \033[32m
YELLOW := \033[33m
CYAN   := \033[36m
RESET  := \033[0m

help: ## Affiche cette aide
	@echo ""
	@echo "$(CYAN)INPTIC RH — Commandes disponibles$(RESET)"
	@echo "══════════════════════════════════════"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-22s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ── Démarrage ─────────────────────────────────────────────────────────

up: check-env ## Démarre tous les services
	@echo "$(CYAN)▶ Démarrage de la stack INPTIC RH...$(RESET)"
	docker compose up -d --build
	@echo "$(GREEN)✅ Stack démarrée$(RESET)"
	@$(MAKE) status

up-monitoring: ## Démarre seulement le monitoring (Prometheus + Grafana + Alertmanager)
	docker compose up -d prometheus alertmanager grafana postgres-exporter

up-app: ## Démarre seulement l'application + DB
	docker compose up -d db app

up-jenkins: ## Démarre seulement Jenkins
	docker compose up -d jenkins

down: ## Arrête tous les services (préserve les volumes)
	@echo "$(YELLOW)⏹ Arrêt de la stack...$(RESET)"
	docker compose down --remove-orphans
	@echo "$(GREEN)✅ Stack arrêtée$(RESET)"

restart: ## Redémarre tous les services
	@$(MAKE) down
	@$(MAKE) up

restart-app: ## Redémarre seulement l'application (zero-downtime)
	docker compose up -d --no-deps --build app
	@echo "$(GREEN)✅ Application redémarrée$(RESET)"

# ── Build ─────────────────────────────────────────────────────────────

build: ## Reconstruit l'image Docker de l'application
	docker build --tag inptic-rh:latest --cache-from inptic-rh:latest .
	@echo "$(GREEN)✅ Image construite$(RESET)"

build-jenkins: ## Reconstruit l'image Jenkins
	docker build --tag inptic-jenkins:latest ./jenkins/
	@echo "$(GREEN)✅ Image Jenkins construite$(RESET)"

# ── Monitoring ────────────────────────────────────────────────────────

reload-prometheus: ## Recharge la config Prometheus à chaud (sans redémarrage)
	@echo "$(CYAN)🔄 Rechargement Prometheus...$(RESET)"
	curl -s -X POST http://localhost:9090/-/reload && echo "$(GREEN)✅ Prometheus rechargé$(RESET)"

reload-alertmanager: ## Recharge la config Alertmanager à chaud
	@echo "$(CYAN)🔄 Rechargement Alertmanager...$(RESET)"
	curl -s -X POST http://localhost:9093/-/reload && echo "$(GREEN)✅ Alertmanager rechargé$(RESET)"

# ── Logs ──────────────────────────────────────────────────────────────

logs: ## Affiche les logs de tous les services (follow)
	docker compose logs -f --tail=50

logs-app: ## Logs de l'application Flask
	docker compose logs -f --tail=100 app

logs-jenkins: ## Logs Jenkins
	docker compose logs -f --tail=100 jenkins

logs-db: ## Logs PostgreSQL
	docker compose logs -f --tail=50 db

# ── Statut ────────────────────────────────────────────────────────────

status: ## Affiche l'état de tous les services
	@echo ""
	@echo "$(CYAN)📊 État des services INPTIC RH$(RESET)"
	@echo "══════════════════════════════════════"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
	@echo ""
	@echo "$(CYAN)🌐 URLs d'accès$(RESET)"
	@echo "  Application  : http://localhost:5000"
	@echo "  Jenkins      : http://localhost:8080"
	@echo "  Grafana      : http://localhost:3000"
	@echo "  Prometheus   : http://localhost:9090"
	@echo "  Alertmanager : http://localhost:9093"
	@echo ""

health: ## Vérifie la santé de l'application
	@echo "$(CYAN)🏥 Health check...$(RESET)"
	@curl -sf http://localhost:5000/health | python3 -m json.tool || echo "$(YELLOW)⚠️  Application non disponible$(RESET)"

ps: ## Alias pour status
	@$(MAKE) status

# ── Backup & Restore ──────────────────────────────────────────────────

backup: ## Crée un backup manuel de PostgreSQL
	@echo "$(CYAN)💾 Backup PostgreSQL...$(RESET)"
	@mkdir -p postgres/backups
	@docker exec postgres-db sh -c \
		'PGPASSWORD=$$POSTGRES_PASSWORD pg_dump -U $$POSTGRES_USER $$POSTGRES_DB' \
		| gzip > postgres/backups/manual_backup_$$(date +%Y%m%d_%H%M%S).sql.gz
	@echo "$(GREEN)✅ Backup créé dans postgres/backups/$(RESET)"
	@ls -lh postgres/backups/*.sql.gz | tail -3

restore: ## Restaure le dernier backup (ATTENTION: écrase les données)
	@echo "$(YELLOW)⚠️  Restauration du dernier backup...$(RESET)"
	@LATEST=$$(ls -t postgres/backups/*.sql.gz 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then echo "Aucun backup trouvé"; exit 1; fi; \
	echo "Restauration de : $$LATEST"; \
	read -p "Confirmer ? (oui/non) : " CONFIRM; \
	if [ "$$CONFIRM" = "oui" ]; then \
		gunzip -c "$$LATEST" | docker exec -i postgres-db sh -c \
			'PGPASSWORD=$$POSTGRES_PASSWORD psql -U $$POSTGRES_USER $$POSTGRES_DB'; \
		echo "$(GREEN)✅ Restauration terminée$(RESET)"; \
	else echo "Annulé"; fi

# ── Nettoyage ─────────────────────────────────────────────────────────

clean: ## Arrête et supprime les conteneurs (préserve les volumes)
	docker compose down --remove-orphans --rmi local
	@echo "$(GREEN)✅ Conteneurs et images locales supprimés$(RESET)"

clean-all: ## ⚠️  DESTRUCTIF — Supprime tout y compris les volumes
	@echo "$(YELLOW)⚠️  ATTENTION : Cette commande supprime TOUTES les données !$(RESET)"
	@read -p "Tapez 'SUPPRIMER' pour confirmer : " CONFIRM; \
	if [ "$$CONFIRM" = "SUPPRIMER" ]; then \
		docker compose down --volumes --remove-orphans --rmi local; \
		echo "$(GREEN)✅ Tout supprimé$(RESET)"; \
	else echo "Annulé"; fi

clean-images: ## Supprime les anciennes images Docker inptic-rh
	@docker images inptic-rh --format "{{.ID}} {{.Tag}}" \
		| grep -v "latest" | awk '{print $$1}' \
		| xargs -r docker rmi -f || true
	@echo "$(GREEN)✅ Anciennes images supprimées$(RESET)"

# ── Webhook Git ───────────────────────────────────────────────────────

webhook-setup: ## Affiche les instructions pour configurer le webhook GitHub/GitLab
	@echo ""
	@echo "$(CYAN)🔗 Configuration du Webhook Git$(RESET)"
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@echo "$(GREEN)GitHub :$(RESET)"
	@echo "  1. Aller dans : Settings → Webhooks → Add webhook"
	@echo "  2. Payload URL : http://<votre-ip>:8080/github-webhook/"
	@echo "  3. Content type : application/json"
	@echo "  4. Events : Just the push event"
	@echo "  5. Active : ✅"
	@echo ""
	@echo "$(GREEN)GitLab :$(RESET)"
	@echo "  1. Aller dans : Settings → Webhooks"
	@echo "  2. URL : http://<votre-ip>:8080/project/inptic-rh"
	@echo "  3. Trigger : Push events"
	@echo "  4. SSL verification : désactiver si HTTP"
	@echo ""
	@echo "$(YELLOW)IP de ce serveur :$(RESET)"
	@hostname -I | awk '{print "  " $$1}' 2>/dev/null || echo "  (non disponible)"
	@echo ""

# ── Vérifications ─────────────────────────────────────────────────────

check-env: ## Vérifie que le fichier .env est configuré
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)⚠️  Fichier .env manquant — copie depuis .env.example$(RESET)"; \
		cp .env.example .env; \
		echo "$(YELLOW)   Éditez .env avec vos vraies valeurs avant de continuer$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ .env présent$(RESET)"

check-docker: ## Vérifie que Docker et Docker Compose sont disponibles
	@docker --version || (echo "$(YELLOW)Docker non installé$(RESET)" && exit 1)
	@docker compose version || (echo "$(YELLOW)Docker Compose non installé$(RESET)" && exit 1)
	@echo "$(GREEN)✅ Docker OK$(RESET)"

# ── Migrations DB ─────────────────────────────────────────────────────

db-migrate: ## Crée une nouvelle migration Alembic
	docker exec flask-app flask db migrate -m "$(MSG)"

db-upgrade: ## Applique les migrations en attente
	docker exec flask-app flask db upgrade

db-history: ## Affiche l'historique des migrations
	docker exec flask-app flask db history

# ── Accès rapide ──────────────────────────────────────────────────────

shell-app: ## Ouvre un shell dans le conteneur Flask
	docker exec -it flask-app sh

shell-db: ## Ouvre psql dans le conteneur PostgreSQL
	docker exec -it postgres-db psql -U $${POSTGRES_USER:-inptic} -d $${POSTGRES_DB:-inptic_db}

shell-jenkins: ## Ouvre un shell dans le conteneur Jenkins
	docker exec -it jenkins bash
