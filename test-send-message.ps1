# Simula o envio de uma mensagem do WhatsApp recebida pelo n8n Webhook
param(
    [string]$Pergunta = "Ola! Qual a diferenca entre o Smartwatch XYZ e o ABC? E como faco para trocar caso tenha defeito?",
    [string]$NumeroCliente = "5519993360243",
    [string]$NomeCliente = "Juliano Longo"
)

$n8nUrl = "http://localhost:5678"
$webhookPath = "whatsapp-webhook"
$targetUrl = "$n8nUrl/webhook/$webhookPath"

$payload = @{
    object = "whatsapp_business_account"
    entry = @(
        @{
            id = "WHATSAPP_BUSINESS_ACCOUNT_ID"
            changes = @(
                @{
                    value = @{
                        messaging_product = "whatsapp"
                        metadata = @{
                            display_phone_number = "5511999999999"
                            phone_number_id = "470271332838881"
                        }
                        contacts = @(
                            @{
                                profile = @{
                                    name = $NomeCliente
                                }
                                wa_id = $NumeroCliente
                            }
                        )
                        messages = @(
                            @{
                                from = $NumeroCliente
                                id = "wamid.TESTE_LOCAL_" + (Get-Random)
                                timestamp = [int][double]::Parse((Get-Date -UFormat %s))
                                text = @{
                                    body = $Pergunta
                                }
                                type = "text"
                            }
                        )
                    }
                    field = "messages"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 6

Write-Host "Enviando mensagem simulada de WhatsApp para o n8n..." -ForegroundColor Cyan
Write-Host "URL: $targetUrl" -ForegroundColor Gray
Write-Host "Pergunta do cliente ($NomeCliente): '$Pergunta'" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $targetUrl -Method Post -Body $payload -ContentType "application/json"
    Write-Host "`nMensagem recebida com sucesso pelo n8n Webhook!" -ForegroundColor Green
    Write-Host "Resposta do Webhook:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
    Write-Host "`nVerifique a execucao e o raciocinio da IA / RAG no painel do n8n em: $n8nUrl/executions" -ForegroundColor Cyan
} catch {
    Write-Host "`nErro ao enviar requisicao ao n8n: $_" -ForegroundColor Red
    Write-Host "Dica: Se o fluxo estiver em modo de teste no editor, use a URL de teste com escuta ativa: $n8nUrl/webhook-test/$webhookPath" -ForegroundColor Yellow
}
