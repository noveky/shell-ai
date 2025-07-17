import argparse
import html
import re
import sys

from .completion import request_completion
from .config import MAX_CONTEXT_LENGTH
from .models import Event, EventType, Ref
from .prompts import PROMPT_TEMPLATE
from .utils import ask_yes_no, escape_printf, indent, print_styled, strip_ansi, styled


def parse_arguments():
    parser = argparse.ArgumentParser(
        prog="shell-ai", formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("--context-file", type=str, help="Path to the context file")
    parser.add_argument("--message", type=str, help="User message to the AI")

    args = parser.parse_args()

    return args.context_file, " ".join(args.message)


def flush_buffer(buffer: Ref[str], acc: Ref[str], event_queue: list[Event]):
    """Print the buffer contents to stderr and clear it."""

    if buffer.value:
        print_styled(buffer.value, "light_grey", end="", flush=True, file=sys.stderr)
        acc.value += buffer.value
        buffer.value = ""


def buffer_handler(buffer: Ref[str], acc: Ref[str], event_queue: list[Event]):
    """Handle the response stream buffer."""

    OPENING_TAG = "<suggest-command>"
    CLOSING_TAG = "</suggest-command>"

    # Check if the buffer contains tags or partial tags
    if buffer.value.find(OPENING_TAG) != -1 or any(
        buffer.value.endswith(OPENING_TAG[: j + 1]) for j in range(len(OPENING_TAG))
    ):
        # Replace tags and trigger event
        while True:
            changed = False

            if run_command_match := re.search(
                rf"{OPENING_TAG}(.*?){CLOSING_TAG}", buffer.value, re.DOTALL
            ):
                # Trigger command suggestion
                command = html.unescape(
                    run_command_match.group(1)
                )  # Unescape &lt;, &gt;, etc.
                buffer.value = (
                    buffer.value[: run_command_match.start()]
                    + styled(command, "light_grey", "underline")
                    + buffer.value[run_command_match.end() :]
                )
                event_queue.append(Event(EventType.SUGGEST_COMMAND, command))
                changed = True

            if not changed:
                break
    else:
        flush_buffer(buffer, acc, event_queue)


def stop_handler(buffer: Ref[str], acc: Ref[str], event_queue: list[Event]):
    flush_buffer(buffer, acc, event_queue)

    # Print an extra newline
    print(file=sys.stderr)


async def main():
    context_file, user_message = parse_arguments()

    # Read the shell session context if context file is provided
    session_context = None
    if context_file:
        try:
            with open(context_file, "r", errors="replace") as f:
                session_context = strip_ansi(f.read())
        except:
            pass

    # Construct the prompt
    prompt = PROMPT_TEMPLATE.format(
        session_context=session_context[-(MAX_CONTEXT_LENGTH or 0) :]
        if session_context is not None
        else "No session context provided",
        user_message=user_message or "suggest",
    )

    # Invoke the LLM API and handle the response
    event_queue: list[Event] = []
    try:
        await request_completion(
            [{"role": "user", "content": prompt}],
            event_queue=event_queue,
            buffer_handler=buffer_handler,
            stop_handler=stop_handler,
        )
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Process the events from the response
    commands_to_run: list[str] = []
    for event in event_queue:
        if event.type == EventType.SUGGEST_COMMAND:
            # Ask the user for confirmation before running the command
            print(
                styled(f"\nAI suggests running this command:", "cyan"), file=sys.stderr
            )
            print(indent(event.data, 2), file=sys.stderr)
            if ask_yes_no(styled(f"Approve?", "cyan")):
                commands_to_run.append(event.data)

    # Construct the combined command
    combined_command = ""
    for i, command in enumerate(commands_to_run, 1):
        combined_command += f"printf {escape_printf(styled(f'\nExecuting approved command ({i}/{len(commands_to_run)}):\n', 'cyan'))};\n"
        # combined_command += f"printf {escape_printf(indent(command, 2) + '\n')};\n"
        combined_command += f"{command.strip()};echo;"
    if commands_to_run:
        combined_command += f"printf {escape_printf(styled(f'Done.\n', 'cyan'))};\n"

    # Write the combined command to stdout, which will be executed in shell using `eval`
    print(combined_command, file=sys.stdout)
