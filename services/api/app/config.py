import os

APP_DATABASE_URL = os.getenv(
    "APP_DATABASE_URL",
    "postgresql://analytics_app:analytics_app_password@localhost:5432/analytics_chatbot",
)
ANALYTICS_DATABASE_URL = os.getenv(
    "ANALYTICS_DATABASE_URL",
    "postgresql://analytics_readonly:analytics_readonly_password@localhost:5432/analytics_chatbot",
)
WEB_ORIGIN = os.getenv("WEB_ORIGIN", "http://192.168.64.5:3000")
MAX_QUERY_ROWS = int(os.getenv("MAX_QUERY_ROWS", "500"))
STATEMENT_TIMEOUT_MS = int(os.getenv("STATEMENT_TIMEOUT_MS", "5000"))
