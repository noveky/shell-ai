#!/bin/bash
set -e

# Tool configuration
TOOL_NAME="shell-ai"
MIN_PYTHON_VERSION="3.12"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Detect user context and set up execution functions
setup_user_context() {
    log_step "Setting up user context..."

    if [[ $EUID -eq 0 ]]; then
        if [[ -n "$SUDO_USER" ]]; then
            # Running with sudo
            TARGET_USER="$SUDO_USER"
            TARGET_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
            TARGET_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
            log_info "Installing for sudo user: $SUDO_USER"
        else
            # Running as root directly
            log_warn "Running as root is not recommended"
            log_warn "The tool will be installed for root user only"
            read -p "Continue anyway? [y/N]: " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
            TARGET_USER="root"
            TARGET_HOME="/root"
            TARGET_SHELL="$SHELL"
            log_info "Installing for root user"
        fi
    else
        # Running as regular user
        TARGET_USER="$USER"
        TARGET_HOME="$HOME"
        TARGET_SHELL="$SHELL"
        log_info "Installing for current user: $USER"
    fi

    if [[ ! -d "$TARGET_HOME" ]]; then
        log_error "Target home directory not found: $TARGET_HOME"
        exit 1
    fi

    log_info "Target user: $TARGET_USER"
    log_info "Target home: $TARGET_HOME"

    # Set up execution context functions
    if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
        # Running with sudo - execute as target user
        run_as_user() { sudo -u "$TARGET_USER" "$@"; }
        run_as_user_with_home() { sudo -u "$TARGET_USER" -H "$@"; }
    else
        # Running as current user (regular user or root)
        run_as_user() { "$@"; }
        run_as_user_with_home() { "$@"; }
    fi
}

# Function to compare version numbers
version_compare() {
    local version1=$1
    local version2=$2

    # Convert versions to arrays
    IFS='.' read -ra ver1 <<<"$version1"
    IFS='.' read -ra ver2 <<<"$version2"

    # Compare major and minor versions
    for i in {0..1}; do
        local v1=${ver1[i]:-0}
        local v2=${ver2[i]:-0}

        if ((v1 > v2)); then
            return 0 # version1 > version2
        elif ((v1 < v2)); then
            return 1 # version1 < version2
        fi
    done

    return 2 # versions are equal
}

# Check Python installation and modules
check_python() {
    log_step "Checking Python installation..."

    # Detect the most recent Python version
    PYTHON_CMD=""
    for version in 3.13 3.12 3.11 3.10 3.9 3.8; do
        if command -v "python$version" &>/dev/null; then
            PYTHON_CMD="python$version"
            break
        fi
    done

    # Fall back to python3 if no specific version found
    if [[ -z "$PYTHON_CMD" ]]; then
        if command -v python3 &>/dev/null; then
            PYTHON_CMD="python3"
        else
            log_error "Python 3 is required but not installed"
            log_info "Please install Python 3 using your package manager:"
            log_info "  Ubuntu/Debian: sudo apt-get install python3 python3-venv python3-pip"
            log_info "  RHEL/CentOS:   sudo yum install python3 python3-venv python3-pip"
            log_info "  Arch:          sudo pacman -S python python-pip"
            exit 1
        fi
    fi

    # Check Python version
    PYTHON_VERSION=$($PYTHON_CMD -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    local required_major=$(echo "$MIN_PYTHON_VERSION" | cut -d. -f1)
    local required_minor=$(echo "$MIN_PYTHON_VERSION" | cut -d. -f2)

    if ! $PYTHON_CMD -c "import sys; exit(0 if sys.version_info >= ($required_major,$required_minor) else 1)" 2>/dev/null; then
        log_error "Python $MIN_PYTHON_VERSION+ required, found $PYTHON_VERSION"
        exit 1
    fi

    log_info "Using Python: $PYTHON_CMD (version: $python_version) ✓"

    # Check venv module
    if ! $PYTHON_CMD -c "import venv" 2>/dev/null; then
        log_error "Python venv module not found"
        log_info "Install it with: sudo apt-get install python3-venv (Ubuntu/Debian)"
        exit 1
    fi
}

# Detect shell and RC file
detect_shell() {
    log_step "Detecting shell configuration..."

    SHELL_NAME=$(basename "$TARGET_SHELL")

    case "$SHELL_NAME" in
    bash)
        RC_FILE="$TARGET_HOME/.bashrc"
        ;;
    *)
        log_error "Unsupported shell: $SHELL_NAME"
        log_info "Supported shells: bash"
        return 1
        ;;
    esac

    log_info "Shell: $SHELL_NAME"
    log_info "RC file: $RC_FILE"
}

# Get project root and set installation directory
get_project_root() {
    log_step "Detecting project source and setting installation directory..."

    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    PROJECT_SOURCE="$SCRIPT_DIR"

    # Verify this looks like the right project
    if [[ ! -f "$PROJECT_SOURCE/requirements.txt" ]]; then
        log_error "requirements.txt not found in $PROJECT_SOURCE"
        log_error "Make sure you're running this script from the project directory"
        exit 1
    fi

    if [[ ! -f "$PROJECT_SOURCE/profile.d/shell-ai.sh" ]]; then
        log_error "profile.d/shell-ai.sh not found in $PROJECT_SOURCE"
        exit 1
    fi

    # Set installation directory
    INSTALL_DIR="$TARGET_HOME/.local/share/$TOOL_NAME"

    log_info "Project source: $PROJECT_SOURCE"
    log_info "Installation directory: $INSTALL_DIR"
}

# Install project files
install_project() {
    log_step "Installing project files..."

    # Create installation directory
    run_as_user mkdir -p "$INSTALL_DIR"

    # Copy project files
    log_info "Copying project files to $INSTALL_DIR..."
    cp -r "$PROJECT_SOURCE"/* "$INSTALL_DIR/"

    # Fix ownership if we copied as root
    if [[ $EUID -eq 0 ]]; then
        log_info "Fixing installation directory ownership..."
        chown -R "$TARGET_USER:" "$INSTALL_DIR"
    fi

    log_info "Project files installed successfully"
}

# Setup virtual environment
setup_venv() {
    log_step "Setting up Python virtual environment..."

    VENV_PATH="$INSTALL_DIR/.venv"

    if [[ -d "$VENV_PATH" ]]; then
        log_info "Removing existing virtual environment..."
        rm -rf "$VENV_PATH"
    fi

    # Create virtual environment without pip using the detected Python version
    log_info "Creating virtual environment with $PYTHON_CMD..."
    run_as_user "$PYTHON_CMD" -m venv --without-pip "$VENV_PATH"

    # Verify venv was created successfully
    VENV_PYTHON="$VENV_PATH/bin/python"
    if [[ ! -f "$VENV_PYTHON" ]]; then
        log_error "Failed to create virtual environment"
        exit 1
    fi

    # Try to install pip using ensurepip
    log_info "Installing pip using ensurepip..."
    if run_as_user "$VENV_PYTHON" -m ensurepip --default-pip &>/dev/null; then
        log_info "Successfully installed pip using ensurepip"
    else
        log_warn "ensurepip failed, attempting to bootstrap pip..."

        # Create temp directory if not exists
        if [[ -z "$TEMP_DIR" ]]; then
            TEMP_DIR=$(mktemp -d)
        fi

        # Ensure we have the bootstrap script
        if [[ ! -f "$TEMP_DIR/get-pip.py" ]]; then
            # Download get-pip.py if not already downloaded
            log_info "Downloading pip bootstrap script..."
            if command -v curl &>/dev/null; then
                curl -sSL https://bootstrap.pypa.io/get-pip.py -o "$TEMP_DIR/get-pip.py"
            elif command -v wget &>/dev/null; then
                wget -q https://bootstrap.pypa.io/get-pip.py -O "$TEMP_DIR/get-pip.py"
            else
                log_error "Neither curl nor wget found. Cannot download pip bootstrap script."
                exit 1
            fi
        fi

        # Try to bootstrap pip
        if run_as_user "$VENV_PYTHON" "$TEMP_DIR/get-pip.py" &>/dev/null; then
            log_info "Successfully bootstrapped pip"
        else
            log_error "Failed to install pip in virtual environment"
            log_error "Both ensurepip and bootstrap methods failed"
            exit 1
        fi
    fi

    # Verify pip is now available
    VENV_PIP="$VENV_PATH/bin/pip"
    if [[ ! -f "$VENV_PIP" ]] || ! run_as_user "$VENV_PIP" --version &>/dev/null; then
        log_error "Pip installation verification failed"
        exit 1
    fi

    # Upgrade pip in venv
    log_info "Upgrading pip in virtual environment..."
    run_as_user "$VENV_PYTHON" -m pip install --upgrade pip

    # Install dependencies
    log_info "Installing Python dependencies..."
    run_as_user "$VENV_PIP" install -r "$INSTALL_DIR/requirements.txt"

    log_info "Virtual environment setup completed successfully"
}

# Configure shell integration
configure_shell() {
    log_step "Configuring shell integration..."

    RC_LINE="source $INSTALL_DIR/profile.d/shell-ai.sh"

    # Create RC file if it doesn't exist
    if [[ ! -f "$RC_FILE" ]]; then
        log_info "Creating $RC_FILE..."
        run_as_user touch "$RC_FILE"
    fi

    # Remove old configuration if it exists
    if grep -q "source.*profile.d/shell-ai.sh" "$RC_FILE" 2>/dev/null; then
        log_info "Removing old shell integration..."
        # Create a temporary file to store the cleaned content
        TEMP_RC=$(mktemp)
        sed '/^# Shell AI$/,/^source .*profile\.d\/shell-ai\.sh$/d' "$RC_FILE" >"$TEMP_RC"
        mv "$TEMP_RC" "$RC_FILE"

        # Fix ownership if needed
        if [[ $EUID -eq 0 ]]; then
            chown "$TARGET_USER:" "$RC_FILE"
        fi
    fi

    # Check if new configuration is already present
    if grep -Fxq "$RC_LINE" "$RC_FILE" 2>/dev/null; then
        log_info "Shell integration already configured"
    else
        log_info "Adding shell integration to $(basename "$RC_FILE")..."

        # Add configuration
        {
            echo ""
            echo "# Shell AI"
            echo "$RC_LINE"
            echo ""
        } >>"$RC_FILE"

        # Fix ownership if needed
        if [[ $EUID -eq 0 ]]; then
            chown "$TARGET_USER:" "$RC_FILE"
        fi
    fi
}

# Setup configuration
setup_config() {
    log_step "Setting up configuration..."

    CONFIG_DIR="$TARGET_HOME/.config/$TOOL_NAME"
    CONFIG_FILE="$CONFIG_DIR/$TOOL_NAME.conf"

    # Create config directory
    run_as_user mkdir -p "$CONFIG_DIR"

    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Configuration file already exists: $CONFIG_FILE"
        read -p "Do you want to reconfigure? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    log_info "Configuring the application..."
    echo

    # Get configuration from user
    local base_url api_key model

    read -rp "Enter your OpenAI-compatible API endpoint (press Enter for default): " base_url

    while true; do
        read -rsp "Enter your API key: " api_key
        echo
        if [[ -n "$api_key" ]]; then
            break
        fi
        log_warn "API key cannot be empty"
    done

    read -rp "Enter your preferred model name (e.g., gpt-4o): " model

    # Write configuration
    local config_content="[DEFAULT]
base-url = $base_url
api-key = $api_key
model = $model"

    echo "$config_content" | run_as_user tee "$CONFIG_FILE" >/dev/null

    # Set secure permissions on config file
    run_as_user chmod 600 "$CONFIG_FILE"
}

install_extensions() {
    log_step "Installing extensions..."

    EXTENSIONS_DIR="$PROJECT_SOURCE/extensions"

    if [[ ! -d "$EXTENSIONS_DIR" ]]; then
        log_warn "Extensions directory not found: $EXTENSIONS_DIR"
        return 0
    fi

    # Loop over each subdirectory in the extensions directory
    for extension_dir in "$EXTENSIONS_DIR"/*/; do
        if [[ -d "$extension_dir" ]]; then
            extension_name="$(basename "$extension_dir")"
            install_script="$extension_dir/install.sh"
            if [[ -f "$install_script" && -x "$install_script" ]]; then
                log_info "Installing $extension_name..."
                run_as_user_with_home bash "$install_script" || log_warn "Installation failed for $extension_name"
            else
                log_warn "No executable install.sh found in $extension_dir"
            fi
        fi
    done

    log_info "Extensions installation completed successfully"
}


# Main installation function
main() {
    setup_user_context
    check_python
    detect_shell
    get_project_root
    install_project
    setup_venv
    configure_shell
    setup_config
    install_extensions

    echo
    log_info "🎉 Installation completed successfully!"
    echo
    log_info "Next steps:"
    log_info "1. Restart your terminal or run: source $RC_FILE"
    log_info "2. Test the installation with ai command"
    echo
    log_info "Python version used: $PYTHON_CMD ($PYTHON_VERSION)"
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Configuration file: $TARGET_HOME/.config/$TOOL_NAME/$TOOL_NAME.conf"
    echo
}

# Run main function
main "$@"
