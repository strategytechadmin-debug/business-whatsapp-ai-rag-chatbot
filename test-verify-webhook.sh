#!/usr/bin/env bash
N8N_URL="http://localhost:5678"
WEBHOOK_PATH="whatsapp-webhook"
CHALLENGE="1158201444"
VERIFY_TOKEN="meu_token_secreto_whatsapp_rag"

TARGET_URL="$N8N_URL/webhook/$WEBHOOK_PATH?hub.mode=subscribe&hub.challenge=$CHALLENGE&hub.verify_token=$VERIFY_TOKEN"

echo "Testando handshake GET do Webhook WhatsApp no n8n..."
echo "URL: $TARGET_URL"

RESPONSE=$(curl -s -w "\n%{http_code}" "$TARGET_URL")
BODY=$(echo "$RESPONSE" | sed '$d')
STATUS=$(echo "$RESPONSE" | tail -n1)

echo "Status HTTP: $STATUS"
echo "Conteúdo recebido: $BODY"

if [ "$BODY" = "$CHALLENGE" ]; then
    echo "SUCESSO! O n8n retornou o hub.challenge corretamente."
else
    echo "Aviso: Se o fluxo não estiver Ativo, certifique-se de ativá-lo ou use /webhook-test/$WEBHOOK_PATH com escuta ativa no editor."
fi
