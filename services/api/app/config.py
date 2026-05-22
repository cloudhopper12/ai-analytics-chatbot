import os

from dotenv import load_dotenv

load_dotenv()

APP_DATABASE_URL = os.getenv("APP_DATABASE_URL", "")
ANALYTICS_DATABASE_URL = os.getenv("ANALYTICS_DATABASE_URL", "")
WEB_ORIGIN = os.getenv("WEB_ORIGIN", "http://localhost:3000")
MAX_QUERY_ROWS = int(os.getenv("MAX_QUERY_ROWS", "500"))
STATEMENT_TIMEOUT_MS = int(os.getenv("STATEMENT_TIMEOUT_MS", "5000"))
