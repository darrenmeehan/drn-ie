# syntax = docker/dockerfile:1.4

# 👆 that there is the magic, load-bearing comment to opt into new features
# note using Docker 23.0.6 does not require the magic comment
FROM darrenmeehan42/zola-rust:images as build

WORKDIR /app

# Build binary
COPY src /app/src
COPY Cargo.toml /app/Cargo.toml
COPY Cargo.lock /app/Cargo.lock
RUN cargo build --release

# Build content
COPY . .
RUN zola build

FROM ubuntu:25.04 as runtime
COPY --from=build /app/target/release/drn-ie /usr/local/bin/drn-ie
COPY --from=build /app/public /app/public

# CTRL-C doesn't work without this, but it's not a good idea to use it
# CMD ["/bin/sh", "-c", "drn-ie", "--content-path", "/app/public"]
CMD ["drn-ie", "--content-path", "/app/public"]
