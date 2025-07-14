import os
import tomllib


config: dict = tomllib.load(
    open(os.path.expanduser("~/.config/bash-ai/bash-ai.conf"), "rb")
)


OPENAI_BASE_URL = str(config.get("base-url", os.getenv("OPENAI_BASE_URL")) or "")
OPENAI_API_KEY = str(config.get("api-key", os.getenv("OPENAI_API_KEY")) or "")
OPENAI_MODEL = str(config.get("model", os.getenv("OPENAI_MODEL")) or "")
