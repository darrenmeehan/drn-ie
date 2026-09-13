FROM mcr.microsoft.com/devcontainers/rust:1-bookworm

# Install just command runner
RUN cargo install just

# Install pinned Zola (official release tarball). Delete this override once
# NixOS/nixpkgs#562808 (zola 0.23.6) merges and the nix shell provides it.
ENV ZOLA_VERSION=0.23.6
ENV ZOLA_SHA256=8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /tmp/zola.tar.gz \
      "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && printf '%s  %s\n' "${ZOLA_SHA256}" /tmp/zola.tar.gz | sha256sum -c - \
    && tar -xzf /tmp/zola.tar.gz -C /tmp \
    && install -m755 /tmp/zola /usr/local/bin/zola \
    && rm /tmp/zola.tar.gz