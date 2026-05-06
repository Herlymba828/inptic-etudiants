#!/usr/bin/env python3
"""
Configuration centralisée de l'application INPTIC RH.
Toutes les valeurs sont lues depuis les variables d'environnement.
"""

import os


class Config:
    # ------------------------------------------------------------------ #
    # Sécurité
    # ------------------------------------------------------------------ #
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    API_TOKEN  = os.getenv('API_TOKEN', '').strip()

    # ------------------------------------------------------------------ #
    # Base de données
    # ------------------------------------------------------------------ #
    DB_USER     = os.getenv('POSTGRES_USER',     'inptic')
    DB_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'inptic2024')
    DB_HOST     = os.getenv('POSTGRES_HOST',     'db')
    DB_PORT     = os.getenv('POSTGRES_PORT',     '5432')
    DB_NAME     = os.getenv('POSTGRES_DB',       'inptic_db')

    SQLALCHEMY_DATABASE_URI = (
        f'postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}'
        f'@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Connection pool — adapté pour gunicorn multi-workers
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size':         int(os.getenv('DB_POOL_SIZE',    '5')),
        'max_overflow':      int(os.getenv('DB_MAX_OVERFLOW', '10')),
        'pool_timeout':      int(os.getenv('DB_POOL_TIMEOUT', '30')),
        'pool_recycle':      int(os.getenv('DB_POOL_RECYCLE', '1800')),  # 30 min
        'pool_pre_ping':     True,   # vérifie la connexion avant usage
    }

    # ------------------------------------------------------------------ #
    # Email
    # ------------------------------------------------------------------ #
    GMAIL_USER         = os.getenv('GMAIL_USER',         '').strip()
    GMAIL_APP_PASSWORD = os.getenv('GMAIL_APP_PASSWORD', '').replace(' ', '').strip()
    NOTIFICATION_EMAIL = os.getenv('NOTIFICATION_EMAIL', '').strip()

    # ------------------------------------------------------------------ #
    # Pagination
    # ------------------------------------------------------------------ #
    PAGE_SIZE_DEFAULT = int(os.getenv('PAGE_SIZE_DEFAULT', '20'))
    PAGE_SIZE_MAX     = int(os.getenv('PAGE_SIZE_MAX',    '100'))

    # ------------------------------------------------------------------ #
    # Environnement
    # ------------------------------------------------------------------ #
    FLASK_ENV    = os.getenv('FLASK_ENV', 'production')
    DEBUG        = FLASK_ENV == 'development'
    JENKINS_TEST = os.getenv('JENKINS_TEST') == 'true'


class TestConfig(Config):
    """Configuration pour les tests Jenkins / CI (SQLite en mémoire)."""
    SQLALCHEMY_DATABASE_URI    = 'sqlite:///:memory:'
    SQLALCHEMY_ENGINE_OPTIONS  = {}   # pas de pool pour SQLite
    TESTING                    = True
    DEBUG                      = False
