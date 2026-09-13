# syntax = docker/dockerfile:1.4

# --- Stage 1: build the Rust server binary (src/main.rs) -----------------
FROM rust:1.96-bookworm AS rust-build

WORKDIR /app
COPY Cargo.toml Cargo.lock /app/
COPY src /app/src
RUN cargo build --release

# --- Stage 2: fetch pinned Zola and build the site content --------------
FROM debian:bookworm-slim AS site-build

ENV ZOLA_VERSION=0.23.6
ENV ZOLA_SHA256=8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN curl -fsSL -o /tmp/zola.tar.gz \
      "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && printf '%s  %s\n' "${ZOLA_SHA256}" /tmp/zola.tar.gz | sha256sum -c - \
    && tar -xzf /tmp/zola.tar.gz -C /tmp \
    && install -m755 /tmp/zola /usr/local/bin/zola \
    && zola --version \
    && zola build

# --- Runtime: serve the built site with the Rust server -----------------
FROM ubuntu:25.04 AS runtime
COPY --from=rust-build /app/target/release/drn-ie /usr/local/bin/drn-ie
COPY --from=site-build /app/public /app/public

CMD ["drn-ie", "--content-path", "/app/public"]