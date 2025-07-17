set -e

echo "[*] Detecting user home..."
if [[ -n "$SUDO_USER" ]]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME="$HOME"
fi

echo "[*] Detecting shell type..."
SHELL_NAME=$(basename "$SHELL")
if [[ "$SHELL_NAME" == "bash" ]]; then
    RC_FILE="$USER_HOME/.bashrc"
else
    echo "Error: Unsupported shell type $SHELL_NAME"
    exit 1
fi
RC_NAME=$(basename "$RC_FILE")

echo "[*] Detecting project root..."
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR"

echo "[*] Checking for Python virtual environment..."
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    echo "[*] Creating Python virtual environment..."
    python3 -m venv "$PROJECT_ROOT/.venv"
fi
PIP="$PROJECT_ROOT/.venv/bin/pip"
if [ -f "$PIP" ]; then
    echo "[*] Installing Python dependencies..."
    "$PIP" install -r "$PROJECT_ROOT/requirements.txt"
else
    echo "Warning: pip not found in Python virtual environment. You need to install pip and required packages manually."
fi

echo "[*] Configuring $RC_NAME..."
RC_LINE="source $PROJECT_ROOT/profile.d/shell-ai.sh"
grep -Fxq "$RC_LINE" "$RC_FILE" || echo -e "\n# Shell AI\n$RC_LINE" >> "$RC_FILE"

CONFIG_DIR="$USER_HOME/.config/shell-ai"
CONFIG_FILE="$CONFIG_DIR/shell-ai.conf"
echo "[*] Creating configuration directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "[*] Configuring the application..."

    read -rp "Enter your OpenAI-compatible API endpoint (default if left empty): " BASE_URL
    read -rp "Enter your API key: " API_KEY
    read -rp "Enter your preferred model name (e.g., gpt-4o): " MODEL

    echo "[*] Writing configuration to $CONFIG_FILE..."
    cat > "$CONFIG_FILE" << CFGEOF
[DEFAULT]
base-url = $BASE_URL
api-key = $API_KEY
model = $MODEL
CFGEOF
else
    echo "[*] Found configuration file at $CONFIG_FILE."
fi

echo "[*] Installation complete."
