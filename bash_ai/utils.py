import re
import sys
from typing import Literal

StyleAttribute = (
    Literal[
        "reset",
        "bold",
        "dim",
        "italic",
        "underline",
        "blink",
        "rapid_blink",
        "reverse",
        "concealed",
        "strike",
        "black",
        "red",
        "green",
        "yellow",
        "blue",
        "magenta",
        "cyan",
        "light_grey",
        "dark_grey",
        "bright_red",
        "bright_green",
        "bright_yellow",
        "bright_blue",
        "bright_magenta",
        "bright_cyan",
        "white",
        "on_black",
        "on_red",
        "on_green",
        "on_yellow",
        "on_blue",
        "on_magenta",
        "on_cyan",
        "on_light_grey",
        "on_dark_grey",
        "on_bright_red",
        "on_bright_green",
        "on_bright_yellow",
        "on_bright_blue",
        "on_bright_magenta",
        "on_bright_cyan",
        "on_white",
    ]
    | None
)


_CODE_MAP = {
    "reset": 0,
    "bold": 1,
    "dim": 2,
    "italic": 3,
    "underline": 4,
    "blink": 5,
    "rapid_blink": 6,
    "reverse": 7,
    "concealed": 8,
    "strike": 9,
    "black": 30,
    "red": 31,
    "green": 32,
    "yellow": 33,
    "blue": 34,
    "magenta": 35,
    "cyan": 36,
    "light_grey": 37,
    "dark_grey": 90,
    "bright_red": 91,
    "bright_green": 92,
    "bright_yellow": 93,
    "bright_blue": 94,
    "bright_magenta": 95,
    "bright_cyan": 96,
    "white": 97,
    "on_black": 40,
    "on_red": 41,
    "on_green": 42,
    "on_yellow": 43,
    "on_blue": 44,
    "on_magenta": 45,
    "on_cyan": 46,
    "on_light_grey": 47,
    "on_dark_grey": 100,
    "on_bright_red": 101,
    "on_bright_green": 102,
    "on_bright_yellow": 103,
    "on_bright_blue": 104,
    "on_bright_magenta": 105,
    "on_bright_cyan": 106,
    "on_white": 107,
}


def styled(text: object, *attrs: StyleAttribute) -> str:
    result = str(text)

    for attr in reversed(attrs):
        if attr is None:
            continue
        result = "\033[%dm%s" % (_CODE_MAP[attr], result)

    result += "\033[0m"

    return result


def print_styled(text: object, *attrs: StyleAttribute, **kwargs):
    print(styled(text, *attrs), **kwargs)


def strip_ansi(ansi_string: str) -> str:
    return re.sub(r"\x1B\[\d+(;\d+){0,2}m", "", ansi_string)


def ask_yes_no(question: str = "", default: bool | None = None) -> bool:
    while True:
        try:
            print(
                f"{question + ' ' if question else ''}[{'Y' if default is True else 'y'}/{'N' if default is False else 'n'}] ",
                end="",
                file=sys.stderr,
            )
            answer = input().lower().strip()
            if answer in ("y", "yes"):
                return True
            elif answer in ("n", "no"):
                return False
            elif answer == "" and default is not None:
                return default
            else:
                raise ValueError("Invalid input.")
        except Exception as e:
            print_styled(f"Error: {e}", "red", file=sys.stderr)
