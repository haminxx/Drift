"""App configuration from environment."""
import os
from dotenv import load_dotenv

load_dotenv()

# PORT is set by Render; default for local run
PORT = int(os.environ.get("PORT", "8000"))
