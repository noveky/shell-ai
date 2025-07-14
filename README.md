# Bash AI Assistant

A smart LLM-based assistant that integrates with your bash terminal to perform context-aware command execution and provide answers to general questions.

## Getting Started

1.  Clone this repository:

    ```bash
    git clone https://github.com/noveky/bash-ai.git
    ```

2.  Create a Python virtual environment and install dependencies:

    ```bash
    cd bash-ai
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    ```

3.  Add the following content to `~/.bashrc`:

    ```bash
    # Session logging
    # initialize session logging with real output capture
    start-session-logging() {
        export SESSION_LOG_INITIALIZED=1
        export SESSION_LOG_FILE="/tmp/bash_session_$(date +%Y%m%d_%H%M%S).log"

        # redirect all output to both terminal and log file
        script -fq "$SESSION_LOG_FILE"
    }

    if [[ -z "$SESSION_LOG_INITIALIZED" && $- == *i* ]]; then
        start-session-logging
    fi

    # Bash AI
    export PATH=$PATH:/path/to/bash-ai/bin  # replace with actual path
    ai() {
        eval $(bash-ai --session-file "$SESSION_LOG_FILE" "$@")
    }
    ```

4.  Source the updated `.bashrc` file:

    ```bash
    source ~/.bashrc
    ```

5.  Create the configuration file `~/.config/bash-ai/bash-ai.conf`, and fill in the values:

    ```
    base-url = "Your OpenAI-compatible API endpoint"
    api-key = "Your API key"
    model = "Your preferred model name"
    ```

6.  Try it out!

    ```
    $ ai Show me how to create and run a simple bash script that prints 'Hello World'.

    Here's how to create and run a simple "Hello World" bash script:

    1. First, let's create the script file:
    touch hello.sh

    2. Now let's add the content to the file:
    echo -e '#!/bin/bash\necho "Hello World"' > hello.sh

    3. Make the script executable:
    chmod +x hello.sh

    4. Finally, run the script:
    ./hello.sh

    AI suggests running this command:
      touch hello.sh
    Approve? [y/n] y

    AI suggests running this command:
      echo -e '#!/bin/bash\necho "Hello World"' > hello.sh
    Approve? [y/n] y

    AI suggests running this command:
      chmod +x hello.sh
    Approve? [y/n] y

    AI suggests running this command:
      ./hello.sh
    Approve? [y/n] y

    The following commands will be executed in order:
    1. touch hello.sh
    2. echo -e '#!/bin/bash\necho "Hello World"' > hello.sh
    3. chmod +x hello.sh
    4. ./hello.sh

    Hello World
    ```

## Contributing

Pull requests are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
