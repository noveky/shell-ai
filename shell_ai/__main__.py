import asyncio
import sys

from .utils import print_styled


if __name__ == "__main__":
    from . import main

    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print_styled("\nProcess interrupted by user.", "yellow", file=sys.stderr)
        sys.exit(0)
