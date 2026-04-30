#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from prometheus_client import Counter, Gauge, Histogram, generate_latest, CollectorRegistry, CONTENT_TYPE_LATEST

# Créer un registre personnalisé
registry = CollectorRegistry()

# Définir les métriques avec labels
etudiants_ajoutes_total = Counter(
    'etudiants_ajoutes_total',
    'Nombre total d\'étudiants ajoutés',
    registry=registry
)

etudiants_supprimes_total = Counter(
    'etudiants_supprimes_total',
    'Nombre total d\'étudiants supprimés',
    registry=registry
)

etudiants_actifs = Gauge(
    'etudiants_actifs',
    'Nombre d\'étudiants actuellement en base',
    registry=registry
)

http_requests_total = Counter(
    'http_requests_total',
    'Nombre total de requêtes HTTP',
    ['method', 'endpoint'],
    registry=registry
)

emails_envoyes_total = Counter(
    'emails_envoyes_total',
    'Nombre total d\'emails envoyés',
    registry=registry
)

# Métriques système additionnelles
http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'Durée des requêtes HTTP en secondes',
    ['method', 'endpoint'],
    registry=registry
)

def metrics_page():
    """
    Retourne les métriques au format Prometheus
    """
    data = generate_latest(registry)
    return data, 200, {'Content-Type': CONTENT_TYPE_LATEST}
