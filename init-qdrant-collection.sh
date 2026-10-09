#!/usr/bin/env bash
set -e

PROVIDER="${1:-Gemini}"
QDRANT_URL="http://localhost:6333"
COLLECTION_NAME="whatsapp_knowledge"

if [ "$PROVIDER" = "OpenAI" ]; then
    VECTOR_SIZE=1536
else
    VECTOR_SIZE=768
fi

echo "Provedor: $PROVIDER (Dimensões: $VECTOR_SIZE)"
echo "Verificando se o Qdrant está ativo em $QDRANT_URL..."

if ! curl -s -f "$QDRANT_URL/readyz" > /dev/null; then
    echo "Erro: O Qdrant não está respondendo em $QDRANT_URL."
    echo "Inicie os containers com: docker compose up -d"
    exit 1
fi
echo "Qdrant está online!"

# Verifica se a coleção já existe e sua dimensão
CURRENT_SIZE=$(curl -s "$QDRANT_URL/collections/$COLLECTION_NAME" | grep -o '"size":[0-9]*' | head -n1 | cut -d: -f2 || echo "")

if [ "$CURRENT_SIZE" = "$VECTOR_SIZE" ]; then
    echo "Coleção '$COLLECTION_NAME' já existe com a dimensão correta ($VECTOR_SIZE)."
    exit 0
elif [ -n "$CURRENT_SIZE" ]; then
    echo "Coleção encontrada com dimensão $CURRENT_SIZE. Deletando para recriar com $VECTOR_SIZE..."
    curl -s -X DELETE "$QDRANT_URL/collections/$COLLECTION_NAME" > /dev/null
fi

echo "Criando coleção '$COLLECTION_NAME' com $VECTOR_SIZE dimensões..."
curl -s -X PUT "$QDRANT_URL/collections/$COLLECTION_NAME" \
  -H "Content-Type: application/json" \
  -d "{
    \"vectors\": {
      \"size\": $VECTOR_SIZE,
      \"distance\": \"Cosine\"
    }
  }"
echo ""
echo "Coleção '$COLLECTION_NAME' criada com sucesso para $PROVIDER ($VECTOR_SIZE dimensões)!"
