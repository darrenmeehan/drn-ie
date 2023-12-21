FROM mcr.microsoft.com/devcontainers/rust:1-bookworm
# Install the wget package
RUN apt-get update && apt-get install -y wget

# Install zola
RUN wget https://github.com/barnumbirr/zola-debian/releases/download/v0.18.0-2/zola_0.18.0-2_amd64_bookworm.deb
RUN dpkg -i zola_0.18.0-2_amd64_bookworm.deb
