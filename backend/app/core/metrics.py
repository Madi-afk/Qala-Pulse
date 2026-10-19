from prometheus_client import Counter

mail_failures = Counter("qalapulse_mail_failures_total", "Failed password recovery deliveries")
