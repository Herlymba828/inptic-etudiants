#!/usr/bin/env python3
"""API INPTIC RH - Gestion des employés"""
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
from sqlalchemy import inspect
import os

app = Flask(__name__)

# Configuration base de données
DB_USER = os.getenv('POSTGRES_USER', 'inptic')
DB_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'inptic2024')
DB_HOST = os.getenv('POSTGRES_HOST', 'db')
DB_NAME = os.getenv('POSTGRES_DB', 'inptic_db')

# Utiliser SQLite pour les tests Jenkins si PostgreSQL n'est pas disponible
if os.getenv('JENKINS_TEST') == 'true':
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}'

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

# Destinataire des emails
DEST_EMAIL = os.getenv('NOTIFICATION_EMAIL', 'herlymba828@gmail.com')

# Répertoire data dans le home de l'utilisateur (accessible)
DATA_DIR = os.path.join(os.path.expanduser('~'), 'inptic_data')
os.makedirs(DATA_DIR, exist_ok=True)

# Initialisation base de données
with app.app_context():
    inspector = inspect(db.engine)
    if 'etudiants' not in inspector.get_table_names():
        db.create_all()
        print(f"✅ Base de données initialisée dans {DATA_DIR}")
    else:
        print("✅ Base de données existante")

# ==========================================
# ROUTES API
# ==========================================

@app.route('/')
def index():
    return jsonify({
        'application': 'INPTIC RH',
        'version': '2.0',
        'status': 'running',
        'data_dir': DATA_DIR
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'database': 'connected'
    }), 200

@app.route('/metrics')
def metrics():
    http_requests_total.labels(method='GET', endpoint='/metrics').inc()
    try:
        etudiants_actifs.set(Etudiant.query.count())
    except:
        etudiants_actifs.set(0)
    return metrics_page()

# ==========================================
# CRUD EMPLOYÉS
# ==========================================

@app.route('/api/employes', methods=['POST'])
def ajouter_employe():
    """Ajoute un employé et envoie un email"""
    http_requests_total.labels(method='POST', endpoint='/api/employes').inc()
    
    try:
        data = request.get_json()
        
        if not all(k in data for k in ['nom', 'prenom', 'email', 'filiere', 'annee']):
            return jsonify({'error': 'Données manquantes'}), 400
        
        if Etudiant.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email déjà utilisé'}), 409
        
        employe = Etudiant(
            nom=data['nom'],
            prenom=data['prenom'],
            email=data['email'],
            filiere=data['filiere'],
            annee=data['annee'],
            date_inscription=datetime.utcnow()
        )
        
        db.session.add(employe)
        db.session.commit()
        
        etudiants_ajoutes_total.inc()
        etudiants_actifs.inc()
        
        # 📧 Envoi email AJOUT
        subject = f"✅ Nouvel employé ajouté — {employe.prenom} {employe.nom}"
        body = f"""
Un nouvel employé a été enregistré dans INPTIC RH.

📋 DÉTAILS
═══════════════════════════════
👤 Nom complet : {employe.prenom} {employe.nom}
📧 Email       : {employe.email}
🏢 Département : {employe.filiere}
📅 Année       : {employe.annee}
🕐 Date        : {employe.date_inscription.strftime('%d/%m/%Y à %H:%M:%S')}
═══════════════════════════════

📌 Action : AJOUT
"""
        
        result = send_email(subject, body, DEST_EMAIL)
        if result:
            emails_envoyes_total.inc()
        
        return jsonify(employe.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/employes', methods=['GET'])
def lister_employes():
    """Liste tous les employés"""
    http_requests_total.labels(method='GET', endpoint='/api/employes').inc()
    employes = Etudiant.query.order_by(Etudiant.date_inscription.desc()).all()
    return jsonify([e.to_dict() for e in employes])

@app.route('/api/employes/<int:id>', methods=['GET'])
def get_employe(id):
    """Détail d'un employé"""
    http_requests_total.labels(method='GET', endpoint='/api/employes/<id>').inc()
    employe = Etudiant.query.get_or_404(id)
    return jsonify(employe.to_dict())

@app.route('/api/employes/<int:id>', methods=['PUT'])
def modifier_employe(id):
    """Modifie un employé"""
    http_requests_total.labels(method='PUT', endpoint='/api/employes/<id>').inc()
    employe = Etudiant.query.get_or_404(id)
    data = request.get_json()
    
    employe.nom = data.get('nom', employe.nom)
    employe.prenom = data.get('prenom', employe.prenom)
    employe.email = data.get('email', employe.email)
    employe.filiere = data.get('filiere', employe.filiere)
    employe.annee = data.get('annee', employe.annee)
    
    db.session.commit()
    return jsonify(employe.to_dict())

@app.route('/api/employes/<int:id>', methods=['DELETE'])
def supprimer_employe(id):
    """Supprime un employé et envoie un email"""
    http_requests_total.labels(method='DELETE', endpoint='/api/employes/<id>').inc()
    employe = Etudiant.query.get_or_404(id)
    
    nom = employe.nom
    prenom = employe.prenom
    email_emp = employe.email
    filiere = employe.filiere
    
    db.session.delete(employe)
    db.session.commit()
    
    etudiants_supprimes_total.inc()
    etudiants_actifs.dec()
    
    # 📧 Envoi email SUPPRESSION
    subject = f"🗑️ Employé supprimé — {prenom} {nom}"
    body = f"""
Un employé a été supprimé de INPTIC RH.

📋 DÉTAILS
═══════════════════════════════
👤 Nom complet : {prenom} {nom}
📧 Email       : {email_emp}
🏢 Département : {filiere}
🕐 Date        : {datetime.utcnow().strftime('%d/%m/%Y à %H:%M:%S')}
═══════════════════════════════

📌 Action : SUPPRESSION
"""
    
    result = send_email(subject, body, DEST_EMAIL)
    if result:
        emails_envoyes_total.inc()
    
    return jsonify({'message': 'Employé supprimé avec succès'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
