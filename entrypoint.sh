#!/bin/sh
set -e

# init só na primeira vez — depois a config vive no volume /root/.gbrain
if [ ! -f "/root/.gbrain/config.json" ]; then
  echo ">> primeira execução: gbrain init (engine Postgres via DATABASE_URL)"
  gbrain init --non-interactive --url "$DATABASE_URL" \
    --embedding-model    "${GBRAIN_EMBEDDING_MODEL:-openrouter:openai/text-embedding-3-small}" \
    --embedding-dimensions "${GBRAIN_EMBEDDING_DIMENSIONS:-1536}" \
    --chat-model         "${GBRAIN_CHAT_MODEL:-openrouter:anthropic/claude-sonnet-4.6}"
fi

# migrações idempotentes (cobre restart/upgrade) + sobe o servidor
gbrain apply-migrations --yes
exec gbrain serve --http --port 3131 --bind 0.0.0.0 --public-url "$PUBLIC_URL"
