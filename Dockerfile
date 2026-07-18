ARG PYTHON_VERSION=3.14

FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libc6-dev \
    git \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-install-project --no-dev

COPY . .

RUN uv sync --frozen --no-dev

FROM python:${PYTHON_VERSION}-slim-bookworm

WORKDIR /code

COPY --from=builder /build /code

ENV PATH="/code/.venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY cli_wrapper.sh /usr/bin/pasarguard-cli
RUN chmod +x /usr/bin/pasarguard-cli

COPY tui_wrapper.sh /usr/bin/pasarguard-tui
RUN chmod +x /usr/bin/pasarguard-tui

COPY healthcheck.sh /code/healthcheck.sh
RUN chmod +x /code/healthcheck.sh

RUN chmod +x /code/start.sh

EXPOSE 8000

ENTRYPOINT ["/code/start.sh"]
