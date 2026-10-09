# Simula o envio de uma mensagem pelo webhook da Evolution API
param(
    [string]$Pergunta = "Ola! Qual a diferenca entre o Smartwatch XYZ e o ABC? E qual a politica de troca?",
    [string]$Numero = "5519993360243",
    [string]$Nome = "Juliano Longo",
    [string]$Instancia = "meu-bot"
)

$n8nUrl = "http://localhost:5678"
$targetUrl = "$n8nUrl/webhook/evolution-webhook"

$payload = @{
    event = "messages.upsert"
    instance = $Instancia
    data = @{
        key = @{
            remoteJid = "$Numero@s.whatsapp.net"
            fromMe = $false
            id = "EVOLUTION_TEST_" + (Get-Random)
        }
        pushName = $Nome
        message = @{
            conversation = $Pergunta
        }
        messageType = "conversation"
    }
} | ConvertTo-Json -Depth 6

Write-Host "Simulando evento 'messages.upsert' da Evolution API para o n8n..." -ForegroundColor Cyan
Write-Host "URL: $targetUrl" -ForegroundColor Gray
Write-Host "Cliente ($Nome / $Numero): '$Pergunta'" -ForegroundColor Yellow

try {
    $res = Invoke-RestMethod -Uri $targetUrl -Method Post -Body $payload -ContentType "application/json"
    Write-Host "`nEvento recebido com sucesso pelo n8n!" -ForegroundColor Green
    Write-Host "Acompanhe a execucao da IA e resposta em: $n8nUrl/executions" -ForegroundColor Cyan
} catch {
    Write-Host "`nErro ao enviar requisicao: $_" -ForegroundColor Red
    Write-Host "Dica: Certifique-se de que o fluxo 'workflow-whatsapp-evolution-gemini.json' foi importado e esta ATIVO no n8n." -ForegroundColor Yellow
}
