# Python Testing Reference

**Load this reference when:** writing Python tests with pytest.

## Fixtures

```python
import pytest

@pytest.fixture
def db_session():
    session = Session(engine)
    session.begin_nested()
    yield session
    session.rollback()

@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c
```

## Parametrization

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("test", "TEST"),
])
def test_uppercase(input, expected):
    assert input.upper() == expected
```

## Mocking

```python
from unittest.mock import patch, MagicMock

@patch("mypackage.external_api")
def test_with_mock(api_mock):
    api_mock.return_value = {"status": "ok"}
    assert my_function()["status"] == "ok"
    api_mock.assert_called_once()
```

## Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation():
    result = await async_function()
    assert result == expected
```

## Running Tests

| Command | Purpose |
|---------|---------|
| `pytest` | Run all tests |
| `pytest -v` | Verbose |
| `pytest -k "test_name"` | Run matching tests |
| `pytest --lf` | Last failed only |
| `pytest --cov=pkg` | Coverage report |
| `pytest -m "not slow"` | Skip slow tests |

## Coverage

```bash
pytest --cov=pkg --cov-report=html
# View: open htmlcov/index.html
```

## Best Practices

- Use descriptive test names: `test_user_authentication_validates_email_format`
- One assertion per test or related assertions
- Use fixtures for setup/teardown
- Mock external dependencies
- Test edge cases and errors
- Parametrize when testing multiple inputs