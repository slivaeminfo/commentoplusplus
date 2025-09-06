# ---------- build stage ----------
FROM debian:bookworm-slim AS build

# базовые инструменты
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make gcc g++ pkg-config gnupg \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 + yarn (classic)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*
# включаем corepack и ставим yarn 1.x
RUN corepack enable && corepack prepare yarn@1.22.19 --activate

# Go 1.22 (через apt хватит для сборки)
RUN apt-get update && apt-get install -y --no-install-recommends golang \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

# соберёт фронт и бэкенд в ./build/prod
RUN make prod

# ---------- run stage ----------
FROM debian:bookworm-slim

# tz/ssl корни, чтобы у https и почты всё было ок
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# копируем весь build/prod (там бинарь и статические файлы)
COPY --from=build /app/build/prod /app/build/prod

# Railway даст PORT, Commento++ можно указать через env COMMENTO_PORT=${PORT}
ENV PATH="/app/build/prod:${PATH}"
CMD ["./build/prod/commento"]

