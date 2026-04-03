"""App configuration from environment."""
import os
from dotenv import load_dotenv

load_dotenv()

# PORT is set by Render; default for local run
PORT = int(os.environ.get("PORT", "8000"))

# --- Wearable OAuth (Fitbit / Garmin). Secrets must not be committed. ---
FITBIT_CLIENT_ID = os.environ.get("FITBIT_CLIENT_ID", "")
FITBIT_CLIENT_SECRET = os.environ.get("FITBIT_CLIENT_SECRET", "")
# Must match Fitbit app registration and iOS URL scheme callback (e.g. drift://oauth/callback)
FITBIT_REDIRECT_URI = os.environ.get("FITBIT_REDIRECT_URI", "drift://oauth/callback")

GARMIN_CLIENT_ID = os.environ.get("GARMIN_CLIENT_ID", "")
GARMIN_CLIENT_SECRET = os.environ.get("GARMIN_CLIENT_SECRET", "")
GARMIN_AUTHORIZATION_URL = os.environ.get("GARMIN_AUTHORIZATION_URL", "")
GARMIN_TOKEN_URL = os.environ.get("GARMIN_TOKEN_URL", "")
GARMIN_OAUTH_SCOPE = os.environ.get("GARMIN_OAUTH_SCOPE", "")
GARMIN_REDIRECT_URI = os.environ.get("GARMIN_REDIRECT_URI", "drift://oauth/garmin/callback")

# Fernet key (url-safe base64 32-byte key) for encrypting tokens at rest in Firestore
TOKEN_ENCRYPTION_KEY = os.environ.get("TOKEN_ENCRYPTION_KEY", "")
