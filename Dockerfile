# syntax = docker/dockerfile:1.4

# 👆 that there is the magic, load-bearing comment to opt into new features
# note using Docker 23.0.6 does not require the magic comment
FROM ubuntu:20.04

# Install required dependencies
RUN set -eux; \
		apt update; \
		apt install -y --no-install-recommends \
			curl ca-certificates gcc gcc-multilib pkg-config libssl-dev \
			;

# Install rustup
RUN set -eux; \
		curl --location --fail \
			"https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init" \
			--output rustup-init; \
		chmod +x rustup-init; \
		./rustup-init -y --no-modify-path --default-toolchain stable; \
		rm rustup-init;

# Add rustup to path, check that it works
ENV PATH=${PATH}:/root/.cargo/bin
RUN set -eux; \
		rustup --version; \
        rustup default stable;

RUN rustup default stable;

WORKDIR /app
COPY src /app/src
COPY Cargo.toml /app/Cargo.toml
COPY Cargo.lock /app/Cargo.lock
RUN cargo build --release
RUN cp target/release/drn-ie /usr/local/bin/drn-ie

RUN curl -L https://github.com/darrenmeehan/drn-ie/releases/latest/download/drn-ie.tar.gz -o /app/drn-ie.tar.gz
RUN ls /app
RUN tar -xvf /app/drn-ie.tar.gz
RUN ls /app/public

# CTRL-C doesn't work without this, but it's not a good idea to use it
CMD ["/bin/sh", "-c", "drn-ie"]
