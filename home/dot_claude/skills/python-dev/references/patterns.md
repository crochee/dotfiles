# Python Patterns Reference

**Load this reference when:** writing Python code, handling data structures.

## Type Hints

```python
def process_items(items: list[str]) -> dict[str, int]:
    ...

def get_user(user_id: str) -> User | None:
    ...

# Complex types
from typing import Optional, Union, Callable
```

## Dataclasses

```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class User:
    id: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    
    def __post_init__(self):
        if "@" not in self.email:
            raise ValueError(f"Invalid email: {self.email}")
```

## Iterators

```python
def read_lines(path: str) -> Iterator[str]:
    with open(path) as f:
        for line in f:
            yield line.strip()

# Generator expression
total = sum(x * x for x in range(1_000_000))
```

## Context Managers

```python
@contextmanager
def timer(name: str):
    start = time.perf_counter()
    yield
    print(f"{name} took {time.perf_counter() - start:.4f}s")

# Usage
with timer("operation"):
    # code here
```

## Decorators

```python
import functools

def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.perf_counter() - start:.4f}s")
        return result
    return wrapper
```

## pathlib

```python
from pathlib import Path

config = Path.home() / ".config" / "app" / "settings.toml"
config.parent.mkdir(parents=True, exist_ok=True)
```

## Async Patterns

```python
import asyncio

async def fetch_all(urls: list[str]) -> list[dict]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [t.result() for t in tasks
```

## Best Practices

| Practice | Example |
|----------|---------|
| Type hints | All function signatures |
| Dataclasses | Internal data structures |
| Pathlib | File paths |
| f-strings | String formatting |
| dataclasses.field | Default factories |

## Don't

| Anti-pattern | Fix |
|--------------|-----|
| Mutable defaults | `def foo(x=None)` then `if x is None: x = []` |
| `== None` | Use `is None` |
| `from module import *` | Explicit imports |
| Bare `except:` | `except SpecificError:` |