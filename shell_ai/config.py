import os
import configparser
import sys


CONFIG_FILE = os.path.expanduser("~/.config/shell-ai/shell-ai.conf")
config = configparser.ConfigParser()

if os.path.exists(CONFIG_FILE):
    config.read(CONFIG_FILE)

OPENAI_BASE_URL = (
    config.get("DEFAULT", "base-url", fallback=None) or os.getenv("OPENAI_BASE_URL")
) or None

OPENAI_API_KEY = config.get("DEFAULT", "api-key", fallback=None) or os.getenv(
    "OPENAI_API_KEY", ""
)

OPENAI_MODEL = config.get("DEFAULT", "model", fallback=None) or os.getenv(
    "OPENAI_MODEL", ""
)

MAX_CONTEXT_LENGTH = None
if config.has_option("DEFAULT", "max-context-length"):
    try:
        MAX_CONTEXT_LENGTH = config.getint("DEFAULT", "max-context-length")
    except ValueError:
        raise ValueError(
            f"{CONFIG_FILE}: Invalid type for max-context-length: must be an integer"
        )
