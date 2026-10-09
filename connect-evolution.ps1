# Script para criar a instância no Evolution API, vincular ao n8n e exibir o QR Code
param(
    [string]$InstanceName = "meu-bot",
    [string]$PhoneNumber = "5519993360243",
    [string]$ApiKey = "B42964AA252642248176A496FB14DF2A",
    [string]$EvolutionUrl = "http://localhost:8081"
)

$ErrorActionPreference = "Stop"

Write-Host "Verificando se o Evolution API esta ativo em $EvolutionUrl..." -ForegroundColor Cyan

try {
    $status = Invoke-RestMethod -Uri "$EvolutionUrl" -Method Get
    Write-Host "Evolution API esta online!" -ForegroundColor Green
} catch {
    Write-Host "Erro: Evolution API nao esta respondendo em $EvolutionUrl." -ForegroundColor Red
    Write-Host "Inicie os containers com: docker compose up -d" -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "apikey" = $ApiKey
    "Content-Type" = "application/json"
}

# 1. Verifica se a instancia ja existe
Write-Host "Verificando instancia '$InstanceName'..." -ForegroundColor Cyan
$instances = @()
try {
    $instances = Invoke-RestMethod -Uri "$EvolutionUrl/instance/fetchInstances" -Method Get -Headers $headers
} catch {}

$instanceExists = $false
foreach ($inst in $instances) {
    $instName = if ($inst.name) { $inst.name } elseif ($inst.instance -and $inst.instance.instanceName) { $inst.instance.instanceName } else { "" }
    if ($instName -eq $InstanceName) {
        $instanceExists = $true
        break
    }
}

if (-not $instanceExists) {
    Write-Host "Criando nova instancia '$InstanceName' com webhook para o n8n..." -ForegroundColor Yellow
    $createBody = @{
        instanceName = $InstanceName
        qrcode = $true
        integration = "WHATSAPP-BAILEYS"
    } | ConvertTo-Json

    try {
        $created = Invoke-RestMethod -Uri "$EvolutionUrl/instance/create" -Method Post -Headers $headers -Body $createBody
        Write-Host "Instancia '$InstanceName' criada com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Aviso ao criar instancia: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Instancia '$InstanceName' ja existe." -ForegroundColor Green
}

# 2. Configura o Webhook apontando diretamente para o n8n dentro da rede Docker
Write-Host "Configurando Webhook da instancia para o n8n..." -ForegroundColor Cyan
$webhookBody = @{
    webhook = @{
        enabled = $true
        url = "http://whatsapp-rag-n8n:5678/webhook/evolution-webhook"
        byEvents = $false
        events = @(
            "MESSAGES_UPSERT"
        )
    }
} | ConvertTo-Json -Depth 5

try {
    $setWebhook = Invoke-RestMethod -Uri "$EvolutionUrl/webhook/set/$InstanceName" -Method Post -Headers $headers -Body $webhookBody
    Write-Host "Webhook configurado com sucesso para: http://whatsapp-rag-n8n:5678/webhook/evolution-webhook" -ForegroundColor Green
} catch {
    Write-Host "Aviso ao configurar webhook: $_" -ForegroundColor Yellow
}

# 3. Obtem o QR Code para conexao
Write-Host "`nObtendo QR Code de conexao do WhatsApp..." -ForegroundColor Cyan
try {
    $connect = Invoke-RestMethod -Uri "$EvolutionUrl/instance/connect/$InstanceName" -Method Get -Headers $headers

    if ($connect.base64) {
        Write-Host "`n>>> QR CODE GERADO COM SUCESSO! <<<" -ForegroundColor Green
        Write-Host "Abra o WhatsApp no celular > Aparelhos Conectados > Conectar um Aparelho e escaneie o QR Code." -ForegroundColor Yellow
        
        # Cria um HTML temporário para exibir o QR Code em tela cheia no navegador
        $htmlPath = "$PSScriptRoot\qrcode-evolution.html"
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>QR Code WhatsApp - Evolution API</title>
    <style>
        body { font-family: Arial, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #0b141a; color: #e9edef; margin: 0; }
        .card { background: #111b21; padding: 30px; border-radius: 12px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.5); }
        img { border-radius: 8px; margin: 20px 0; background: white; padding: 10px; }
        h1 { margin-top: 0; color: #00a884; }
        p { font-size: 16px; color: #8696a0; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Conectar WhatsApp (Evolution API)</h1>
        <p>1. Abra o WhatsApp no seu celular<br>2. Toque em <b>Mais opções (⋮)</b> ou <b>Configurações</b><br>3. Selecione <b>Aparelhos conectados</b> > <b>Conectar um aparelho</b><br>4. Aponte a câmera para este código:</p>
        <img src="$($connect.base64)" alt="QR Code WhatsApp" width="300" height="300">
        <p>Instância: <b>$InstanceName</b></p>
    </div>
</body>
</html>
"@
        Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
        Write-Host "Abrindo QR Code no seu navegador padrao..." -ForegroundColor Cyan
        Start-Process $htmlPath
    } elseif ($connect.instance.state -eq "open" -or $connect.state -eq "open") {
        Write-Host "O WhatsApp JA ESTA CONECTADO nesta instancia!" -ForegroundColor Green
    } else {
        Write-Host "Resposta da conexao: " -ForegroundColor Yellow
        Write-Host ($connect | ConvertTo-Json -Depth 3)
    }
} catch {
    Write-Host "Erro ao obter QR Code: $_" -ForegroundColor Red
}
