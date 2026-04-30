#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, jsonify
from models import db, Etudiant
from email_service import send_email
from metrics import (
    etudiants_ajoutes_total,
    etudiants_supprimes_total,
    etudiants_actifs,
    http_requests_total,
    emails_envoyes_total,
    metrics_page
)
from datetime import datetime
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

app = Flask(__name__)

# Configuration de la base de données
DB_USER = os.getenv('POSTGRES_USER', 'inptic')
DB_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'inptic2024')
DB_HOST = os.getenv('POSTGRES_HOST', 'db')
DB_NAME = os.getenv('POSTGRES_DB', 'inptic_db')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

db.init_app(app)

# Configuration de l'email administrateur
ADMIN_EMAIL = os.getenv('ADMIN_EMAIL', 'admin@inptic.dz')

# Route d'accueil
@app.route('/')
def index():
    return jsonify({
        'application': 'Gestion Étudiants INPTIC',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'api': '/api/etudiants',
            'metrics': '/metrics',
            'health': '/health'
        }
    })

# Route de santé
@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

# Route pour les métriques Prometheus
@app.route('/metrics')
def metrics():
    http_requests_total.labels(method='GET', endpoint='/metrics').inc()
    # Mise à jour du gauge d'étudiants actifs
    try:
        etudiants_actifs.set(Etudiant.query.count())
    except:
        etudiants_actifs.set(0)
    return metrics_page()

# === ROUTES CRUD ÉTUDIANTS ===

@app.route('/api/etudiants', methods=['POST'])
def ajouter_etudiant():
    http_requests_total.labels(method='POST', endpoint='/api/etudiants').inc()
    
    try:
        data = request.get_json()
        
        # Validation des données
        if not all(k in data for k in ['nom', 'prenom', 'email', 'filiere', 'annee']):
            return jsonify({'error': 'Données manquantes'}), 400
        
        # Vérifier si l'email existe déjà
        if Etudiant.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Cet email existe déjà'}), 409
        
        etudiant = Etudiant(
            nom=data['nom'],
            prenom=data['prenom'],
            email=data['email'],
            filiere=data['filiere'],
            annee=data['annee'],
            date_inscription=datetime.utcnow()
        )
        
        db.session.add(etudiant)
        db.session.commit()
        
        # Incrémenter les métriques
        etudiants_ajoutes_total.inc()
        etudiants_actifs.inc()
        
        # Envoyer email de notification
        subject = f"✅ Nouvel étudiant ajouté — {etudiant.prenom} {etudiant.nom}"
        body = f"""Un nouvel étudiant a été enregistré dans le système.

    Nom    : {etudiant.nom}
    Prénom : {etudiant.prenom}
    Email  : {etudiant.email}
    Filière: {etudiant.filiere}
    Année  : {etudiant.annee}
    Date   : {etudiant.date_inscription.strftime('%d/%m/%Y %H:%M:%S')}
    """
        try:
            send_email(subject, body, ADMIN_EMAIL)
            emails_envoyes_total.inc()
        except Exception as e:
            app.logger.error(f"Erreur lors de l'envoi de l'email: {e}")
        
        return jsonify(etudiant.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants', methods=['GET'])
def lister_etudiants():
    http_requests_total.labels(method='GET', endpoint='/api/etudiants').inc()
    try:
        etudiants = Etudiant.query.order_by(Etudiant.date_inscription.desc()).all()
        return jsonify([e.to_dict() for e in etudiants]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants/<int:id>', methods=['GET'])
def get_etudiant(id):
    http_requests_total.labels(method='GET', endpoint='/api/etudiants/<id>').inc()
    etudiant = Etudiant.query.get_or_404(id)
    return jsonify(etudiant.to_dict()), 200

@app.route('/api/etudiants/<int:id>', methods=['PUT'])
def modifier_etudiant(id):
    http_requests_total.labels(method='PUT', endpoint='/api/etudiants/<id>').inc()
    etudiant = Etudiant.query.get_or_404(id)
    data = request.get_json()
    
    try:
        etudiant.nom = data.get('nom', etudiant.nom)
        etudiant.prenom = data.get('prenom', etudiant.prenom)
        etudiant.email = data.get('email', etudiant.email)
        etudiant.filiere = data.get('filiere', etudiant.filiere)
        etudiant.annee = data.get('annee', etudiant.annee)
        
        db.session.commit()
        return jsonify(etudiant.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants/<int:id>', methods=['DELETE'])
def supprimer_etudiant(id):
    http_requests_total.labels(method='DELETE', endpoint='/api/etudiants/<id>').inc()
    etudiant = Etudiant.query.get_or_404(id)
    
    # Stocker les infos avant suppression pour l'email
    nom = etudiant.nom
    prenom = etudiant.prenom
    email = etudiant.email
    
    try:
        db.session.delete(etudiant)
        db.session.commit()
        
        # Mettre à jour les métriques
        etudiants_supprimes_total.inc()
        etudiants_actifs.dec()
        
        # Envoyer email de notification
        subject = f"🗑️ Étudiant supprimé — {prenom} {nom}"
        body = f"""Un étudiant a été supprimé du système.

    Nom    : {nom}
    Prénom : {prenom}
    Email  : {email}
    Date   : {datetime.utcnow().strftime('%d/%m/%Y %H:%M:%S')}
    """
        try:
            send_email(subject, body, ADMIN_EMAIL)
            emails_envoyes_total.inc()
        except Exception as e:
            app.logger.error(f"Erreur lors de l'envoi de l'email: {e}")
        
        return jsonify({'message': 'Étudiant supprimé avec succès'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Créer les tables au démarrage
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

