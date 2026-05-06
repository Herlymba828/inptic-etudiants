#!/usr/bin/env python3
"""Service d'envoi d'emails pour INPTIC RH"""
import smtplib
import ssl
import os
import threading
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email_async(subject, body, to_email):
    """Envoie un email de manière asynchrone (non-bloquant)"""
    thread = threading.Thread(target=send_email, args=(subject, body, to_email))
    thread.daemon = True
    thread.start()
    return True

def send_email(subject, body, to_email):
    """
    Envoie un email via :
    1. Postfix relay local (port 25) — priorité
    2. Gmail SSL direct (port 465) — fallback
    3. Gmail STARTTLS direct (port 587) — fallback
    """
    try:
        gmail_user = os.getenv('SMTP_USER', os.getenv('GMAIL_USER', 'ingridboussoyi@gmail.com'))
        gmail_password = os.getenv('SMTP_PASSWORD', os.getenv('GMAIL_APP_PASSWORD', ''))
        password = gmail_password.replace(' ', '').strip()

        if not gmail_user:
            print("❌ SMTP_USER non configuré")
            return False

        print(f"📧 Envoi email : {gmail_user} → {to_email}")
        print(f"   Sujet : {subject[:60]}...")

        # Créer le message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = f"INPTIC RH <{gmail_user}>"
        msg['To'] = to_email
        msg['Reply-To'] = gmail_user

        # Version texte
        msg.attach(MIMEText(body, 'plain', 'utf-8'))

        # Version HTML
        html = f"""<!DOCTYPE html>
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
        .content h2 {{ color: #1a5276; margin-top: 0; font-size: 18px; }}
        .details {{ background: #f8f9fa; border-left: 4px solid #2e86c1; padding: 15px 20px; margin: 15px 0; border-radius: 0 8px 8px 0; font-family: monospace; font-size: 14px; line-height: 1.8; }}
        .footer {{ background: #1a5276; color: rgba(255,255,255,0.8); padding: 15px; text-align: center; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="icon">🎓</div>
            <h1>INPTIC RH</h1>
            <p>Système de Gestion des Étudiants</p>
        </div>
        <div class="content">
            <h2>{subject}</h2>
            <div class="details">
                {body.replace(chr(10), '<br>').replace(' ', '&nbsp;')}
            </div>
        </div>
        <div class="footer">
            <p>📧 Notification automatique — INPTIC RH</p>
            <p>{datetime.now().strftime('%d/%m/%Y à %H:%M:%S')}</p>
            <p style="margin-top:8px;font-size:10px;">© 2026 INPTIC — Tous droits réservés</p>
        </div>
    </div>
</body>
</html>"""
        msg.attach(MIMEText(html, 'html', 'utf-8'))

        # ── Méthode 1 : Postfix relay local (port 25) ──────────────
        try:
            print(f"   🔄 Tentative via Postfix relay (postfix:25)...")
            with smtplib.SMTP('postfix', 25, timeout=10) as server:
                server.ehlo('inptic-mail')
                server.send_message(msg)
            print(f"   ✅ EMAIL ENVOYÉ via Postfix relay !")
            print(f"   📬 Destinataire : {to_email}")
            return True
        except Exception as e:
            print(f"   ⚠️ Postfix relay échoué : {str(e)[:80]}")

        # ── Méthode 2 : Gmail SSL direct (port 465) ────────────────
        if not password:
            print("   ❌ SMTP_PASSWORD vide — impossible d'utiliser Gmail direct")
            return False

        try:
            print(f"   🔄 Tentative Gmail SSL (port 465)...")
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=context, timeout=30) as server:
                server.login(gmail_user, password)
                server.send_message(msg)
            print(f"   ✅ EMAIL ENVOYÉ via Gmail SSL !")
            print(f"   📬 Destinataire : {to_email}")
            return True
        except smtplib.SMTPAuthenticationError:
            print(f"   ❌ Authentification Gmail échouée")
            print(f"   ➜ Vérifiez : https://myaccount.google.com/apppasswords")
            return False
        except Exception as e:
            print(f"   ⚠️ Gmail SSL échoué : {str(e)[:80]}")

        # ── Méthode 3 : Gmail STARTTLS (port 587) ─────────────────
        try:
            print(f"   🔄 Tentative Gmail STARTTLS (port 587)...")
            context = ssl.create_default_context()
            with smtplib.SMTP('smtp.gmail.com', 587, timeout=30) as server:
                server.ehlo()
                server.starttls(context=context)
                server.ehlo()
                server.login(gmail_user, password)
                server.send_message(msg)
            print(f"   ✅ EMAIL ENVOYÉ via Gmail STARTTLS !")
            print(f"   📬 Destinataire : {to_email}")
            return True
        except Exception as e:
            print(f"   ⚠️ Gmail STARTTLS échoué : {str(e)[:80]}")

        print(f"   ❌ Toutes les méthodes d'envoi ont échoué")
        return False

    except Exception as e:
        print(f"❌ Erreur critique email_service : {str(e)}")
        return False
