# Python Deployment Reference

**Load this reference when:** deploying Python applications.

## Environment Management

| Tool | Use |
|------|-----|
| `venv` | Standard library isolation |
| `uv` | Fast package manager (recommended) |
| `pipx` | CLI tools installation |

```bash
# Create environment
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt

# Or with uv
uv sync
```

## Docker

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install uv
COPY pyproject.toml .
RUN uv pip install --system -r requirements.txt
COPY . .
RUN uv pip install --system -e .

FROM python:3.12-slim
WORKDIR /app
RUN useradd -r -u 1001 appuser
COPY --from=builder /usr/local /usr/local
COPY --from=builder /home/appuser /home/appuser
USER appuser
ENV PYTHONUNBUFFERED=1
CMD ["python", "-m", "myapp"]
```

## Production Servers

| Server | Type | Use |
|--------|------|-----|
| Gunicorn | WSGI | Django, Flask |
| Uvicorn | ASGI | FastAPI, async |
| Hypercorn | ASGI | Quart, BlackSheep |

```bash
gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 4
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## Dependencies

```toml
[project]
name = "myapp"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = ["fastapi>=0.110", "pydantic>=2.0"]

[project.optional-dependencies]
dev = ["pytest>=8", "pytest-cov", "ruff", "mypy"]
```

## Best Practices

- Pin dependency versions
- Use non-root user in Docker
- Set `PYTHONUNBUFFERED=1` for logs
- Use `--no-cache-dir` in Docker for smaller images
- Multi-stage builds to exclude dev dependencies