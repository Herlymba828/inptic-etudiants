#!/bin/sh
# ============================================================
# Initialise alertmanager.yml avec les vraies valeurs d'env
# Appelé par docker-compose via un entrypoint wrapper
# ============================================================
set -e

CONFIG_SRC="/etc/alertmanager/alertmanager.yml"
CONFIG_TMP="/tmp/alertmanager.yml"

# Vérification des variables requises
if [ -z "$GMAIL_USER" ] || [ -z "$GMAIL_APP_PASSWORD" ] || [ -z "$NOTIFICATION_EMAIL" ]; then
    echo "[alertmanager-init] ⚠️  Variables GMAIL_USER, GMAIL_APP_PASSWORD ou NOTIFICATION_EMAIL manquantes"
    echo "[alertmanager-init] Les notifications email ne fonctionneront pas."
fi

# Substitution des placeholders
sed \
    -e "s|GMAIL_USER_PLACEHOLDER|${GMAIL_USER:-noreply@example.com}|g" \
    -e "s|GMAIL_PASSWORD_PLACEHOLDER|${GMAIL_APP_PASSWORD:-}|g" \
    -e "s|NOTIFICATION_EMAIL_PLACEHOLDER|${NOTIFICATION_EMAIL:-admin@example.com}|g" \
    "$CONFIG_SRC" > "$CONFIG_TMP"

# Remplacer la config par la version substituée
cp "$CONFIG_TMP" "$CONFIG_SRC"

echo "[alertmanager-init] ✅ Configuration initialisée pour ${GMAIL_USER:-non configuré}"

# Lancer alertmanager avec les arguments originaux
exec /bin/alertmanager "$@"
