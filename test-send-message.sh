#!/usr/bin/env bash
PERGUNTA="${1:-Olá! Qual a diferença entre o Smartwatch XYZ e o ABC? E como funciona a troca em caso de defeito?}"
NUMERO="${2:-5511988887777}"
NOME="${3:-Juliano Longo}"

N8N_URL="http://localhost:5678"
WEBHOOK_PATH="whatsapp-webhook"
TARGET_URL="$N8N_URL/webhook/$WEBHOOK_PATH"

echo "Enviando mensagem simulada do WhatsApp para o n8n..."
echo "URL: $TARGET_URL"
echo "Pergunta: $PERGUNTA"

TIMESTAMP=$(date +%s)

PAYLOAD=$(cat <<EOF
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "5511999999999",
              "phone_number_id": "470271332838881"
            },
            "contacts": [
              {
                "profile": {
                  "name": "$NOME"
                },
                "wa_id": "$NUMERO"
              }
            ],
            "messages": [
              {
                "from": "$NUMERO",
                "id": "wamid.TESTE_LOCAL_$TIMESTAMP",
                "timestamp": "$TIMESTAMP",
                "text": {
                  "body": "$PERGUNTA"
                },
                "type": "text"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
EOF
)

curl -s -X POST "$TARGET_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo ""
echo "Requisição enviada! Verifique a execução no painel do n8n em $N8N_URL/executions"
