import asyncio
import os
from collections.abc import Callable

import openai

from .config import OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL
from .models import Event, Message, Ref


async def request_completion(
    messages: list,
    *,
    event_queue: list[Event] | None = None,
    buffer_handler: Callable[[Ref[str], Ref[str], list[Event]], None] | None = None,
    start_handler: Callable[[Ref[str], Ref[str], list[Event]], None] | None = None,
    stop_handler: Callable[[Ref[str], Ref[str], list[Event]], None] | None = None,
) -> Message:
    client = openai.AsyncOpenAI(base_url=OPENAI_BASE_URL, api_key=OPENAI_API_KEY)
    model = OPENAI_MODEL

    response = await client.chat.completions.create(
        model=model,
        messages=messages,
        stream=True,
    )

    stream = (
        chunk.choices[0].delta.content
        async for chunk in response
        if chunk.choices and chunk.choices[0].delta.content is not None
    )

    # Handle stream
    first_token_received = False
    buffer = Ref("")
    buffer_lock = asyncio.Lock()
    acc = Ref("")

    if start_handler:
        start_handler(buffer, acc, event_queue if event_queue is not None else [])

    async for token in stream:
        async with buffer_lock:
            if not first_token_received:
                first_token_received = True
            buffer.value += token

            if buffer_handler:
                buffer_handler(
                    buffer, acc, event_queue if event_queue is not None else []
                )
            else:
                acc.value += buffer.value
                buffer.value = ""

    if stop_handler:
        stop_handler(buffer, acc, event_queue if event_queue is not None else [])

    return {"role": "assistant", "content": acc.value}
