import os
import tomllib


CONFIG_FILE = os.path.expanduser("~/.config/bash-ai/bash-ai.conf")
config: dict = tomllib.load(open(CONFIG_FILE, "rb"))


OPENAI_BASE_URL = str(config.get("base-url", os.getenv("OPENAI_BASE_URL")) or "")
OPENAI_API_KEY = str(config.get("api-key", os.getenv("OPENAI_API_KEY")) or "")
OPENAI_MODEL = str(config.get("model", os.getenv("OPENAI_MODEL")) or "")
MAX_CONTEXT_LENGTH = config.get("max-context-length", None)
if not isinstance(MAX_CONTEXT_LENGTH, int) and MAX_CONTEXT_LENGTH is not None:
    raise ValueError(
        f"{CONFIG_FILE}: Invalid type for max-context-length: {MAX_CONTEXT_LENGTH.__class__.__name__}."
    )
