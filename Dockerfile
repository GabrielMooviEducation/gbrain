FROM oven/bun:1

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# instala o CLI do gbrain
RUN git clone --depth 1 https://github.com/garrytan/gbrain.git /opt/gbrain \
    && cd /opt/gbrain && bun install && bun link

WORKDIR /brain
EXPOSE 3131

# aplica migrações (idempotente) e sobe o servidor HTTP
CMD gbrain apply-migrations --yes && \
    gbrain serve --http --port 3131 --bind 0.0.0.0 --public-url "$PUBLIC_URL"
