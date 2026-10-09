FROM python:3.11-slim as builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on

WORKDIR /app

RUN pip install uv

COPY pyproject.toml .python-version ./
RUN uv pip install --system --no-cache -r <(uv pip compile pyproject.toml) || uv pip install --system .

COPY . .

EXPOSE 50051

CMD ["python", "main.py"]
