FROM mcr.microsoft.com/devcontainers/rust:0-1-bullseye
# Install the utils packages
RUN apt-get update && apt-get install -y xz-utils wget

# Install zola
RUN wget https://github.com/barnumbirr/zola-debian/releases/download/v0.17.2-1/zola_0.17.2-1_amd64_bullseye.deb
RUN dpkg -i zola_0.17.2-1_amd64_bullseye.deb