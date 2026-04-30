#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Etudiant(db.Model):
    __tablename__ = 'etudiants'
    
    id = db.Column(db.Integer, primary_key=True)
    nom = db.Column(db.String(100), nullable=False)
    prenom = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    filiere = db.Column(db.String(100), nullable=False)
    annee = db.Column(db.String(20), nullable=False)
    date_inscription = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'nom': self.nom,
            'prenom': self.prenom,
            'email': self.email,
            'filiere': self.filiere,
            'annee': self.annee,
            'date_inscription': self.date_inscription.strftime('%Y-%m-%d %H:%M:%S')
        }
    
    def __repr__(self):
        return f'<Etudiant {self.prenom} {self.nom}>'
