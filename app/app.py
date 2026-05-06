#!/usr/bin/env python3
"""API INPTIC RH - Gestion des étudiants"""
from flask import Flask, request, jsonify, send_from_directory
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
from sqlalchemy import inspect, or_, func
import os

app = Flask(__name__, static_folder='static', static_url_path='/static')

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

# Initialisation base de données
with app.app_context():
    inspector = inspect(db.engine)
    if 'etudiants' not in inspector.get_table_names():
        db.create_all()
        print("✅ Base de données initialisée")
    else:
        print("✅ Base de données existante")

# ==========================================
# ROUTES FRONTEND
# ==========================================

@app.route('/')
def frontend():
    """Sert le frontend HTML"""
    return send_from_directory('static', 'index.html')

@app.route('/api')
def api_info():
    """Information sur l'API"""
    return jsonify({
        'application': 'INPTIC RH API',
        'version': '2.0',
        'status': 'running',
        'endpoints': {
            'frontend': '/',
            'api_etudiants': '/api/etudiants',
            'api_stats': '/api/stats',
            'health': '/health',
            'metrics': '/metrics'
        }
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
# CRUD ÉTUDIANTS
# ==========================================

@app.route('/api/etudiants', methods=['POST'])
def ajouter_etudiant():
    """Ajoute un étudiant et envoie un email"""
    http_requests_total.labels(method='POST', endpoint='/api/etudiants').inc()
    
    try:
        data = request.get_json()
        
        if not all(k in data for k in ['nom', 'prenom', 'email', 'filiere', 'annee']):
            return jsonify({'error': 'Données manquantes'}), 400
        
        if Etudiant.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email déjà utilisé'}), 409
        
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
        
        etudiants_ajoutes_total.inc()
        etudiants_actifs.inc()
        
        # 📧 Envoi email AJOUT
        subject = f"✅ Nouvel étudiant ajouté — {etudiant.prenom} {etudiant.nom}"
        body = f"""
Un nouvel étudiant a été enregistré dans INPTIC RH.

📋 DÉTAILS
═══════════════════════════════
👤 Nom complet : {etudiant.prenom} {etudiant.nom}
📧 Email       : {etudiant.email}
🏢 Filière     : {etudiant.filiere}
📅 Année       : {etudiant.annee}
🕐 Date        : {etudiant.date_inscription.strftime('%d/%m/%Y à %H:%M:%S')}
═══════════════════════════════

📌 Action : AJOUT
"""
        
        result = send_email(subject, body, DEST_EMAIL)
        if result:
            emails_envoyes_total.inc()
        
        return jsonify(etudiant.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants', methods=['GET'])
def lister_etudiants():
    """Liste tous les étudiants avec pagination et filtres"""
    http_requests_total.labels(method='GET', endpoint='/api/etudiants').inc()
    
    try:
        # Paramètres de pagination
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # Paramètres de filtrage
        search = request.args.get('search', '').strip()
        filiere = request.args.get('filiere', '').strip()
        annee = request.args.get('annee', '').strip()
        
        # Construction de la requête
        query = Etudiant.query
        
        if search:
            search_pattern = f'%{search}%'
            query = query.filter(
                or_(
                    Etudiant.nom.ilike(search_pattern),
                    Etudiant.prenom.ilike(search_pattern),
                    Etudiant.email.ilike(search_pattern)
                )
            )
        
        if filiere:
            query = query.filter(Etudiant.filiere == filiere)
        
        if annee:
            query = query.filter(Etudiant.annee == annee)
        
        # Pagination
        query = query.order_by(Etudiant.date_inscription.desc())
        paginated = query.paginate(page=page, per_page=per_page, error_out=False)
        
        return jsonify({
            'data': [e.to_dict() for e in paginated.items],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': paginated.total,
                'pages': paginated.pages
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants/<int:id>', methods=['GET'])
def get_etudiant(id):
    """Détail d'un étudiant"""
    http_requests_total.labels(method='GET', endpoint='/api/etudiants/<id>').inc()
    etudiant = Etudiant.query.get_or_404(id)
    return jsonify(etudiant.to_dict())

@app.route('/api/etudiants/<int:id>', methods=['PUT'])
def modifier_etudiant(id):
    """Modifie un étudiant"""
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
        return jsonify(etudiant.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/etudiants/<int:id>', methods=['DELETE'])
def supprimer_etudiant(id):
    """Supprime un étudiant et envoie un email"""
    http_requests_total.labels(method='DELETE', endpoint='/api/etudiants/<id>').inc()
    etudiant = Etudiant.query.get_or_404(id)
    
    nom = etudiant.nom
    prenom = etudiant.prenom
    email_etu = etudiant.email
    filiere = etudiant.filiere
    
    try:
        db.session.delete(etudiant)
        db.session.commit()
        
        etudiants_supprimes_total.inc()
        etudiants_actifs.dec()
        
        # 📧 Envoi email SUPPRESSION
        subject = f"🗑️ Étudiant supprimé — {prenom} {nom}"
        body = f"""
Un étudiant a été supprimé de INPTIC RH.

📋 DÉTAILS
═══════════════════════════════
👤 Nom complet : {prenom} {nom}
📧 Email       : {email_etu}
🏢 Filière     : {filiere}
🕐 Date        : {datetime.utcnow().strftime('%d/%m/%Y à %H:%M:%S')}
═══════════════════════════════

📌 Action : SUPPRESSION
"""
        
        result = send_email(subject, body, DEST_EMAIL)
        if result:
            emails_envoyes_total.inc()
        
        return jsonify({'message': 'Étudiant supprimé avec succès'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Statistiques pour le dashboard"""
    http_requests_total.labels(method='GET', endpoint='/api/stats').inc()
    
    try:
        # Total étudiants
        total = Etudiant.query.count()
        
        # Par filière
        par_filiere = db.session.query(
            Etudiant.filiere,
            func.count(Etudiant.id).label('count')
        ).group_by(Etudiant.filiere).all()
        
        # Par année
        par_annee = db.session.query(
            Etudiant.annee,
            func.count(Etudiant.id).label('count')
        ).group_by(Etudiant.annee).order_by(Etudiant.annee).all()
        
        return jsonify({
            'total_etudiants': total,
            'par_filiere': [{'filiere': f, 'count': c} for f, c in par_filiere],
            'par_annee': [{'annee': a, 'count': c} for a, c in par_annee]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
