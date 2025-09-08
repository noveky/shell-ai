# Session logging
log() {
    if [[ -z $1 ]]; then
        echo "Usage: log {start|status|file|list|view|clear|stop|update}"
    elif [[ $1 == start ]]; then
        if [[ -f "$SESSION_LOG_FILE" ]]; then
            echo "Session logging already started, file: $SESSION_LOG_FILE" >&2
            return 1
        fi
        export SESSION_LOG_FILE="/tmp/shell-session-logs/$(date +%Y%m%d_%H%M%S)"
        mkdir -p $(dirname "$SESSION_LOG_FILE")
        # Start scripting
        shopt -q login_shell 2>/dev/null && LOGIN_FLAG=-l
        exec script -fq "$SESSION_LOG_FILE" -c "$SHELL $LOGIN_FLAG"
        return 0
    elif [[ $1 == status ]]; then
        if [[ -f "$SESSION_LOG_FILE" ]]; then
            echo "Session logging started, file: $SESSION_LOG_FILE" >&2
            return 0
        else
            echo "Session logging not started" >&2
            return 1
        fi
    elif [[ $1 == file ]]; then
        if log status 2>/dev/null; then
            echo "$SESSION_LOG_FILE"
            return 0
        else
            echo "Session logging not started" >&2
            return 1
        fi
    elif [[ $1 == list ]]; then
        ls -lA "$(dirname "$SESSION_LOG_FILE")"
    elif [[ $1 == view ]]; then
        if log status 2>/dev/null; then
            # Use tail to avoid following the file while it's being written to
            # Use cat -e to escape ANSI in the output
            tail -n +1 "$SESSION_LOG_FILE" | cat -e && echo
        else
            echo "Session logging not started" >&2
            return 1
        fi
    elif [[ $1 == clear ]]; then
        : >"$SESSION_LOG_FILE"
    elif [[ $1 == stop ]]; then
        rm -f "$SESSION_LOG_FILE"
        unset SESSION_LOG_FILE
    elif [[ $1 == update ]]; then
        # Start logging if accidentally terminated
        if [[ -n "$SESSION_LOG_FILE" && ! -f "$SESSION_LOG_FILE" ]]; then
            log start 2>/dev/null
        fi
        # Update prompt
        LOG_INDICATOR_TEXT="✱ "
        LOG_INDICATOR="\[\e[38;2;255;99;132m\]${LOG_INDICATOR_TEXT}\[\e[0m\]"
        if [[ -n "$SESSION_LOG_FILE" ]]; then
            # Add logging indicator if not already present
            if [[ "$PS1" != *"✱"* ]]; then
                PS1="${LOG_INDICATOR}${PS1}"
            fi
        else
            # Remove logging indicator
            PS1="${PS1//$LOG_INDICATOR_TEXT}"
        fi
    fi
}

# Set PROMPT_COMMAND to automatically update prompt before each command
PROMPT_COMMAND="log update${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Start session logging
log start 2>/dev/null
log update
trap 'log stop' EXIT

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
