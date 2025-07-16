#!/bin/bash
set -e

if [[ -n "$SUDO_USER" ]]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME="$HOME"
fi

echo "[*] Detecting project root..."
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

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

echo "[*] Configuring .bashrc..."
BASHRC_LINE="source $PROJECT_ROOT/profile.d/bash-ai.sh"
grep -Fxq "$BASHRC_LINE" "$USER_HOME/.bashrc" || echo -e "\n# Bash AI\n$BASHRC_LINE" >> "$USER_HOME/.bashrc"

CONFIG_DIR="$USER_HOME/.config/bash-ai"
CONFIG_FILE="$CONFIG_DIR/bash-ai.conf"
echo "[*] Creating configuration directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "[*] Configuring the application..."

    read -rp "Enter your OpenAI-compatible API endpoint (default if left empty): " BASE_URL
    read -rp "Enter your API key: " API_KEY
    read -rp "Enter your preferred model name (e.g., gpt-4o): " MODEL

    echo "[*] Writing configuration to $CONFIG_FILE..."
    cat > "$CONFIG_FILE" << CFGEOF
base-url = "$BASE_URL"
api-key = "$API_KEY"
model = "$MODEL"
CFGEOF
    echo "[*] Configuration written to $CONFIG_FILE."
else
    echo "Found configuration file at $CONFIG_FILE."
fi

echo "[*] Sourcing .bashrc..."
source "$USER_HOME/.bashrc"

echo "[*] Installation complete."
