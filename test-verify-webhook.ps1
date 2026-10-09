# Simula o teste de verificacao GET que o Meta WhatsApp Cloud API realiza ao registrar o Webhook
$ErrorActionPreference = "Stop"

$n8nUrl = "http://localhost:5678"
$webhookPath = "whatsapp-webhook"
$challenge = "1158201444"
$verifyToken = "meu_token_secreto_whatsapp_rag"

# No n8n, ao testar, a URL pode ser /webhook-test/ ou /webhook/ se ativo
$targetUrl = "$n8nUrl/webhook/$webhookPath?hub.mode=subscribe&hub.challenge=$challenge&hub.verify_token=$verifyToken"

Write-Host "Testando handshake do Webhook com Meta em:" -ForegroundColor Cyan
Write-Host "$targetUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $targetUrl -Method Get
    Write-Host "`nStatus Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Resposta recebida do n8n: $($response.Content)" -ForegroundColor Green

    if ($response.Content -eq $challenge) {
        Write-Host "`nSUCESSO! O n8n respondeu exatamente com o challenge esperado: $challenge" -ForegroundColor Green
        Write-Host "A verificacao do Meta WhatsApp Cloud API funcionara perfeitamente." -ForegroundColor Green
    } else {
        Write-Host "`nAviso: O conteudo retornado foi diferente do challenge enviado." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`nFalha na chamada ao webhook: $_" -ForegroundColor Red
    Write-Host "Dica: Se o fluxo ainda nao estiver 'Ativo' (toggle no canto superior direito do n8n), clique em 'Listen for test event' no no Verify e use a URL de teste: $n8nUrl/webhook-test/$webhookPath" -ForegroundColor Yellow
}
