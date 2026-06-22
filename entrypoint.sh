#!/bin/sh
set -e

CONC="${GBRAIN_WORKER_CONCURRENCY:-2}"

# 1) init só na primeira vez — engine Postgres via DATABASE_URL (config no volume /root/.gbrain)
if [ ! -f "/root/.gbrain/config.json" ]; then
  echo ">> primeira execução: gbrain init (engine Postgres via DATABASE_URL)"
  gbrain init --non-interactive --url "$DATABASE_URL" \
    --embedding-model      "${GBRAIN_EMBEDDING_MODEL:-openrouter:openai/text-embedding-3-small}" \
    --embedding-dimensions "${GBRAIN_EMBEDDING_DIMENSIONS:-1536}" \
    --chat-model           "${GBRAIN_CHAT_MODEL:-openrouter:anthropic/claude-sonnet-4.6}"
fi

# 2) migrações idempotentes (cobre restart/upgrade)
gbrain apply-migrations --yes

# 3) worker de background: processa embeddings, /ingest e enrichment.
#    Postgres-only. Roda destacado; o supervisor reinicia o worker se ele cair.
#    O retry limpa um PID-lock obsoleto que pode ter sobrado no volume após restart.
echo ">> iniciando worker (gbrain jobs supervisor, concurrency=$CONC)"
gbrain jobs supervisor start --detach --json --concurrency "$CONC" || {
  echo ">> lock obsoleto? parando e tentando de novo"
  gbrain jobs supervisor stop || true
  gbrain jobs supervisor start --detach --json --concurrency "$CONC" \
    || echo "!! AVISO: worker não iniciou — embeddings não vão processar"
}

# 4) servidor HTTP em foreground (PID 1)
exec gbrain serve --http --port 3131 --bind 0.0.0.0 --public-url "$PUBLIC_URL"
