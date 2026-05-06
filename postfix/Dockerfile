FROM debian:bookworm-slim

# Installer Postfix et les outils nécessaires
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        postfix \
        libsasl2-modules \
        ca-certificates \
        mailutils \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Copier la configuration
COPY main.cf /etc/postfix/main.cf
COPY sasl_passwd /etc/postfix/sasl_passwd

# Sécuriser et hasher le fichier de credentials
RUN postmap /etc/postfix/sasl_passwd && \
    chmod 600 /etc/postfix/sasl_passwd && \
    chmod 600 /etc/postfix/sasl_passwd.db

# Script de démarrage
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25

ENTRYPOINT ["/entrypoint.sh"]
