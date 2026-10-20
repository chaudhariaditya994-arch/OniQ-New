import os
import smtplib
import ssl
from email.message import EmailMessage
from pathlib import Path

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "465"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_USE_TLS = os.getenv("SMTP_USE_TLS", "true").lower() in ("1", "true", "yes")
EMAIL_FROM_ADDRESS = os.getenv("EMAIL_FROM_ADDRESS") or SMTP_USERNAME
EMAIL_FROM_NAME = os.getenv("EMAIL_FROM_NAME", "OnionGuard")
FEEDBACK_RECIPIENT = os.getenv("FEEDBACK_RECIPIENT") or SMTP_USERNAME

LOGO_PATH = Path(__file__).resolve().parent.parent / "onion-icon-512.png"

CODE_EXPIRY_MINUTES = 15


def _build_html(code: str) -> str:
    return f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background-color:#f5f7f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f5f7f5;padding:32px 16px;">
    <tr><td align="center">
      <table role="presentation" width="480" cellspacing="0" cellpadding="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.04);max-width:480px;">
        <tr>
          <td style="background:linear-gradient(135deg,#4CAF50 0%,#388E3C 100%);padding:32px 24px;text-align:center;">
            <img src="cid:onionguard_logo" alt="OnionGuard" width="80" height="80" style="display:block;margin:0 auto;border-radius:16px;">
            <h1 style="color:#ffffff;margin:16px 0 0 0;font-size:24px;font-weight:600;letter-spacing:-0.3px;">OnionGuard</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:32px 32px 16px 32px;">
            <h2 style="margin:0 0 16px 0;font-size:20px;color:#1a1a1a;font-weight:600;">Reset your password</h2>
            <p style="margin:0 0 24px 0;font-size:15px;line-height:1.6;color:#555;">
              We received a request to reset the password for your OnionGuard account. Use the verification code below to continue.
            </p>
            <div style="background-color:#f0f9f0;border:2px dashed #4CAF50;border-radius:12px;padding:24px;text-align:center;margin:24px 0;">
              <div style="font-size:32px;font-weight:700;color:#2E7D32;letter-spacing:8px;font-family:'SF Mono',Consolas,Menlo,monospace;">{code}</div>
              <p style="margin:8px 0 0 0;font-size:13px;color:#777;">Enter this code in the OnionGuard app</p>
            </div>
            <p style="margin:24px 0 0 0;font-size:14px;line-height:1.6;color:#888;">
              This code expires in <strong>{CODE_EXPIRY_MINUTES} minutes</strong>. If you didn't request a password reset, you can safely ignore this email &mdash; your password won't change.
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:0 32px 32px 32px;">
            <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
            <p style="margin:0;font-size:12px;color:#999;text-align:center;line-height:1.6;">
              AI-Powered Onion Disease Detection for Farmers in Ghana<br>
              <a href="https://onion-guard.duckdns.org" style="color:#4CAF50;text-decoration:none;">onion-guard.duckdns.org</a>
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""


def _build_text(code: str) -> str:
    return f"""OnionGuard - Password Reset

We received a request to reset the password for your OnionGuard account.

Your verification code: {code}

Enter this code in the OnionGuard app to set a new password.
The code expires in {CODE_EXPIRY_MINUTES} minutes.

If you didn't request a password reset, you can safely ignore this email
your password won't change.

---
OnionGuard - AI-Powered Onion Disease Detection for Farmers in Ghana
https://onion-guard.duckdns.org
"""


def send_reset_email(to_email: str, code: str) -> None:
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        raise RuntimeError("SMTP credentials not configured (SMTP_USERNAME / SMTP_PASSWORD)")

    msg = EmailMessage()
    msg["Subject"] = "Reset your OnionGuard password"
    msg["From"] = f"{EMAIL_FROM_NAME} <{EMAIL_FROM_ADDRESS}>"
    msg["To"] = to_email

    msg.set_content(_build_text(code))
    msg.add_alternative(_build_html(code), subtype="html")

    if LOGO_PATH.exists():
        with open(LOGO_PATH, "rb") as f:
            msg.get_payload()[1].add_related(
                f.read(), maintype="image", subtype="png", cid="<onionguard_logo>"
            )

    _send_via_smtp(msg)


def _send_via_smtp(msg: EmailMessage) -> None:
    context = ssl.create_default_context()
    # Port 465 uses implicit TLS (SMTPS); port 587 uses STARTTLS upgrade.
    if SMTP_PORT == 465:
        with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context) as server:
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
    else:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.ehlo()
            if SMTP_USE_TLS:
                server.starttls(context=context)
                server.ehlo()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)


def _build_feedback_html(user_name: str, user_email: str, subject: str, message: str) -> str:
    safe_msg = (message or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n", "<br>")
    safe_subject = (subject or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    safe_name = (user_name or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    safe_email = (user_email or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background-color:#f5f7f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f5f7f5;padding:32px 16px;">
    <tr><td align="center">
      <table role="presentation" width="560" cellspacing="0" cellpadding="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.04);max-width:560px;">
        <tr>
          <td style="background:linear-gradient(135deg,#4CAF50 0%,#388E3C 100%);padding:24px;text-align:center;">
            <img src="cid:onionguard_logo" alt="OnionGuard" width="64" height="64" style="display:block;margin:0 auto;border-radius:12px;">
            <h1 style="color:#ffffff;margin:12px 0 0 0;font-size:20px;font-weight:600;letter-spacing:-0.3px;">New User Feedback</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:24px 28px 8px 28px;">
            <p style="margin:0 0 4px 0;font-size:13px;color:#999;">From</p>
            <p style="margin:0 0 16px 0;font-size:15px;color:#1a1a1a;font-weight:600;">{safe_name} &lt;<a href="mailto:{safe_email}" style="color:#4CAF50;text-decoration:none;">{safe_email}</a>&gt;</p>
            <p style="margin:0 0 4px 0;font-size:13px;color:#999;">Subject</p>
            <p style="margin:0 0 20px 0;font-size:15px;color:#1a1a1a;font-weight:500;">{safe_subject}</p>
            <p style="margin:0 0 4px 0;font-size:13px;color:#999;">Message</p>
            <div style="background-color:#f9faf9;border-left:3px solid #4CAF50;padding:16px;border-radius:6px;font-size:14px;line-height:1.6;color:#333;">{safe_msg}</div>
          </td>
        </tr>
        <tr>
          <td style="padding:0 28px 24px 28px;">
            <hr style="border:none;border-top:1px solid #eee;margin:20px 0 16px 0;">
            <p style="margin:0;font-size:12px;color:#999;text-align:center;line-height:1.5;">
              Sent via the Talk To Us form in the OnionGuard mobile app.<br>
              Reply directly to <a href="mailto:{safe_email}" style="color:#4CAF50;text-decoration:none;">{safe_email}</a> to respond to the user.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""


def send_feedback_email(user_name: str, user_email: str, subject: str, message: str) -> None:
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        raise RuntimeError("SMTP credentials not configured (SMTP_USERNAME / SMTP_PASSWORD)")

    msg = EmailMessage()
    msg["Subject"] = f"[OnionGuard Feedback] {subject or '(no subject)'}"
    msg["From"] = f"{EMAIL_FROM_NAME} <{EMAIL_FROM_ADDRESS}>"
    msg["To"] = FEEDBACK_RECIPIENT
    msg["Reply-To"] = user_email or EMAIL_FROM_ADDRESS

    plaintext = (
        f"New OnionGuard user feedback\n\n"
        f"From: {user_name} <{user_email}>\n"
        f"Subject: {subject}\n\n"
        f"---\n{message}\n---\n\n"
        f"Reply directly to {user_email} to respond."
    )
    msg.set_content(plaintext)
    msg.add_alternative(_build_feedback_html(user_name, user_email, subject, message), subtype="html")

    if LOGO_PATH.exists():
        with open(LOGO_PATH, "rb") as f:
            msg.get_payload()[1].add_related(
                f.read(), maintype="image", subtype="png", cid="<onionguard_logo>"
            )

    _send_via_smtp(msg)
