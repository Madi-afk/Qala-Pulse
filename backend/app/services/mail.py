"""TLS-only SMTP; message bodies and recipient addresses never enter application logs."""

import logging
import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import get_settings

logger = logging.getLogger("qalapulse.mail")


def send_mail(recipient: str, subject: str, body: str) -> None:
    settings = get_settings()
    message = EmailMessage()
    message["From"] = settings.smtp_from
    message["To"] = recipient
    message["Subject"] = subject
    message.set_content(body)
    context = ssl.create_default_context()
    connection: smtplib.SMTP
    if settings.smtp_tls == "ssl":
        connection = smtplib.SMTP_SSL(
            settings.smtp_host, settings.smtp_port, timeout=15, context=context
        )
    else:
        connection = smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15)
    with connection as smtp:
        if settings.smtp_tls == "starttls":
            smtp.starttls(context=context)
        if settings.smtp_username:
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)


def deliver_reset(recipient: str, token: str, language: str) -> None:
    from app.core.metrics import mail_failures

    settings = get_settings()
    url = f"{settings.public_api_url.rstrip('/')}/account/#token={token}&lang={language}"
    if language == "kk":
        subject = "QalaPulse: құпиясөзді қалпына келтіру"
        body = f"Құпиясөзді өзгерту: {url}\nСілтеме {settings.password_reset_minutes} минут жарамды.\nСұрау жібермесеңіз, бұл хатты елемеңіз."
    else:
        subject = "QalaPulse: восстановление пароля"
        body = f"Изменить пароль: {url}\nСсылка действует {settings.password_reset_minutes} минут.\nЕсли вы не запрашивали сброс, проигнорируйте письмо."
    try:
        send_mail(recipient, subject, body)
    except Exception:
        mail_failures.inc()
        logger.error("password_reset_delivery_failed")
