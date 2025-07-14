from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any, Generic, TypeVar

Message = dict[str, str]


T = TypeVar("T")


@dataclass
class Ref(Generic[T]):
    value: T


class EventType(Enum):
    SUGGEST_COMMAND = auto()


@dataclass
class Event:
    type: EventType
    data: Any
