#!/bin/bash
set -e

echo "🚀 Démarrage du relay SMTP Postfix..."

# Mettre à jour les credentials depuis les variables d'environnement
if [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASSWORD" ]; then
    echo "📧 Configuration SMTP : $SMTP_USER"
    echo "[142.251.127.109]:587 ${SMTP_USER}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd.db
    echo "✅ Credentials SMTP configurés"
fi

# Mettre à jour le hostname si fourni
if [ -n "$MAIL_HOSTNAME" ]; then
    postconf -e "myhostname = $MAIL_HOSTNAME"
fi

# Démarrer Postfix
echo "📬 Démarrage de Postfix..."
postfix start-fg &
POSTFIX_PID=$!

# Attendre que Postfix soit prêt
sleep 3

echo "✅ Postfix relay SMTP démarré"
echo "   Relay : smtp.gmail.com:587"
echo "   User  : ${SMTP_USER}"
echo "   Port  : 25 (interne Docker)"

# Garder le processus en vie
wait $POSTFIX_PID
