#!/usr/bin/env python3
"""Service d'envoi d'emails pour INPTIC RH"""
import smtplib
import ssl
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email(subject, body, to_email):
    """
    Envoie un email Gmail
    Émetteur : ingridboussoyi@gmail.com
    Destinataire : herlymba828@gmail.com
    """
    # Utiliser les variables SMTP_* du .env
    gmail_user = os.getenv('SMTP_USER', os.getenv('GMAIL_USER', 'ingridboussoyi@gmail.com'))
    gmail_password = os.getenv('SMTP_PASSWORD', os.getenv('GMAIL_APP_PASSWORD', ''))
    
    # Nettoyer le mot de passe (sans espaces)
    password = gmail_password.replace(' ', '').strip()
    
    if not gmail_user or not password:
        print("❌ Configuration email manquante")
        print(f"   SMTP_USER = {gmail_user}")
        print(f"   SMTP_PASSWORD = {'***' if password else 'VIDE'}")
        return False
    
    print(f"📧 Envoi email : {gmail_user} → {to_email}")
    print(f"   Sujet : {subject[:60]}...")
    
    # Créer le message
    msg = MIMEMultipart('alternative')
    msg['Subject'] = subject
    msg['From'] = f"INPTIC RH <{gmail_user}>"
    msg['To'] = to_email
    
    # Version HTML
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }}
            .container {{ max-width: 600px; margin: 20px auto; background: white; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); overflow: hidden; }}
            .header {{ background: linear-gradient(135deg, #1a5276, #2e86c1); color: white; padding: 30px; text-align: center; }}
            .header h1 {{ margin: 0; font-size: 26px; letter-spacing: 1px; }}
            .header p {{ margin: 8px 0 0 0; opacity: 0.9; font-size: 14px; }}
            .icon {{ font-size: 48px; margin-bottom: 10px; }}
            .content {{ padding: 30px; }}
            .content h2 {{ color: #1a5276; margin-top: 0; }}
            .details {{ background: #f8f9fa; border-left: 4px solid #2e86c1; padding: 15px; margin: 15px 0; border-radius: 0 8px 8px 0; }}
            .details p {{ margin: 8px 0; line-height: 1.6; }}
            .badge {{ display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 12px; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; }}
            .badge-success {{ background: #d4edda; color: #155724; }}
            .badge-danger {{ background: #f8d7da; color: #721c24; }}
            .footer {{ background: #1a5276; color: rgba(255,255,255,0.8); padding: 15px; text-align: center; font-size: 12px; }}
            .footer a {{ color: white; text-decoration: underline; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="icon">🏢</div>
                <h1>INPTIC RH</h1>
                <p>Système de Gestion des Ressources Humaines</p>
            </div>
            <div class="content">
                <h2>{subject}</h2>
                <div class="details">
                    {body.replace(chr(10), '<br>')}
                </div>
            </div>
            <div class="footer">
                <p>📧 Email automatique envoyé par INPTIC RH</p>
                <p>{datetime.now().strftime('%d/%m/%Y à %H:%M:%S')}</p>
                <p style="margin-top:8px;font-size:10px;">© 2026 INPTIC - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    msg.attach(MIMEText(body, 'plain', 'utf-8'))
    msg.attach(MIMEText(html, 'html', 'utf-8'))
    
    # Essayer SSL (port 465)
    try:
        print(f"   🔄 Connexion SSL (port 465)...")
        context = ssl.create_default_context()
        with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=context, timeout=60) as server:
            server.login(gmail_user, password)
            server.send_message(msg)
        print(f"   ✅ EMAIL ENVOYÉ AVEC SUCCÈS !")
        print(f"   📬 Destinataire : {to_email}")
        return True
    except smtplib.SMTPAuthenticationError:
        print(f"   ❌ Erreur d'authentification")
        print(f"   Vérifiez le mot de passe d'application pour {gmail_user}")
        print(f"   ➜ https://myaccount.google.com/apppasswords")
        return False
    except Exception as e:
        print(f"   ⚠️ SSL échoué : {str(e)[:80]}")
    
    # Essayer STARTTLS (port 587)
    try:
        print(f"   🔄 Connexion STARTTLS (port 587)...")
        context = ssl.create_default_context()
        with smtplib.SMTP('smtp.gmail.com', 587, timeout=60) as server:
            server.ehlo()
            server.starttls(context=context)
            server.ehlo()
            server.login(gmail_user, password)
            server.send_message(msg)
        print(f"   ✅ EMAIL ENVOYÉ AVEC SUCCÈS !")
        print(f"   📬 Destinataire : {to_email}")
        return True
    except Exception as e:
        print(f"   ⚠️ STARTTLS échoué : {str(e)[:80]}")
    
    print(f"   ❌ Impossible d'envoyer l'email")
    return False
