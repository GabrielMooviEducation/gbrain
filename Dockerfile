FROM oven/bun:1

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# instala o gbrain a partir do fonte (fallback determinístico do manual)
RUN git clone --depth 1 https://github.com/garrytan/gbrain.git /opt/gbrain \
    && cd /opt/gbrain && bun install

# wrapper estável no PATH (bin = src/cli.ts rodado pelo bun)
RUN printf '#!/bin/sh\nexec bun /opt/gbrain/src/cli.ts "$@"\n' > /usr/local/bin/gbrain \
    && chmod +x /usr/local/bin/gbrain

WORKDIR /brain
ENV HOME=/root
EXPOSE 3131

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
