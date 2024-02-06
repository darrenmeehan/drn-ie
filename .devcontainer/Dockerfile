FROM mcr.microsoft.com/devcontainers/rust:1-bookworm
# Install the wget package
RUN apt-get update && apt-get install -y wget

# Install zola
RUN wget https://github.com/barnumbirr/zola-debian/releases/download/v0.18.0-2/zola_0.18.0-2_amd64_bookworm.deb
RUN dpkg -i zola_0.18.0-2_amd64_bookworm.deb

# All of Node.js just for Netlify CLI
RUN apt install -y ca-certificates curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
ARG NODE_MAJOR=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt update && apt-get install nodejs -y
RUN npm install netlify-cli -g

# Install just command runner
RUN cargo install just
