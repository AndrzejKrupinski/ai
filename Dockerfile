FROM oven/bun:latest

# Install dependencies required for Node.js and native builds
RUN apt-get update && apt-get install -y curl build-essential
RUN apt-get update && apt-get install -y netcat-openbsd

# Install Node.js (e.g., Node LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && node -v && npm -v

WORKDIR /app

COPY package.json bun.lockb ./
RUN bun install

COPY . .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
