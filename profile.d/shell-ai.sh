# Session logging
log() {
    if [[ -z $1 ]]; then
        echo "Usage: log {start|status|file|view|clear|stop}"
    elif [[ $1 == start ]]; then
        export SESSION_LOG_FILE="/tmp/shell-session-logs/$(date +%Y%m%d_%H%M%S)"
        mkdir -p $(dirname "$SESSION_LOG_FILE")
        shopt -q login_shell 2>/dev/null && LOGIN_FLAG=-l
        exec script -fq "$SESSION_LOG_FILE" -c "$SHELL $LOGIN_FLAG"
    elif [[ $1 == status ]]; then
        if [[ -f "$SESSION_LOG_FILE" ]]; then
            echo "Session logging initialized, file: $SESSION_LOG_FILE"
        else
            echo "Session logging not initialized."
        fi
    elif [[ $1 == file ]]; then
        echo "$SESSION_LOG_FILE"
    elif [[ $1 == list ]]; then
        ls -lA "$(dirname "$SESSION_LOG_FILE")"
    elif [[ $1 == view ]]; then
        cat -e "$SESSION_LOG_FILE"
        echo ""
    elif [[ $1 == clear ]]; then
        : >"$SESSION_LOG_FILE"
    elif [[ $1 == stop ]]; then
        rm -f "$SESSION_LOG_FILE"
    fi
}
if [[ ! -f "$SESSION_LOG_FILE" && $- == *i* ]]; then
    log start
fi
trap 'log stop' EXIT

# Logging indicator
if [[ $- == *i* ]]; then
    if [[ -f "$SESSION_LOG_FILE" ]]; then
        PS1="\[\e[38;2;255;99;132m\]✱\[\e[0m\] $PS1"
    fi
fi

# Override clear command
clear() {
    log clear
    command clear
}

# Shell AI integration
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT="$(dirname $SCRIPT_DIR)"
export PATH="$PATH:$PROJECT_ROOT/bin"
ai-agent() {
    eval "$(shell-ai --agent-name "$1" --context-file "$SESSION_LOG_FILE" -- "$2")"
}
ai() {
    ai-agent "" "$*"
}
