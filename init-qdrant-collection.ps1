# Script para inicializar ou recriar a coleção no Qdrant Vector Store
param(
    [ValidateSet("Gemini", "OpenAI")]
    [string]$Provider = "Gemini",
    [switch]$ForceRecreate = $false
)

$ErrorActionPreference = "Stop"

$qdrantUrl = "http://localhost:6333"
$collectionName = "whatsapp_knowledge"

# Dimensão vetorial de acordo com o provedor de IA:
# Google Gemini (text-embedding-004): 768 dimensões
# OpenAI (text-embedding-3-small): 1536 dimensões
$vectorSize = if ($Provider -eq "Gemini") { 768 } else { 1536 }

Write-Host "Provedor selecionado: $Provider (Dimensao dos vetores: $vectorSize)" -ForegroundColor Cyan
Write-Host "Verificando se o Qdrant esta ativo em $qdrantUrl..." -ForegroundColor Cyan

try {
    $health = Invoke-RestMethod -Uri "$qdrantUrl/readyz" -Method Get
    Write-Host "Qdrant esta online e pronto!" -ForegroundColor Green
} catch {
    Write-Host "Erro: O Qdrant nao esta respondendo em $qdrantUrl." -ForegroundColor Red
    Write-Host "Inicie os containers com: docker compose up -d" -ForegroundColor Yellow
    exit 1
}

$needsCreation = $true

try {
    $colInfo = Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Get
    $currentSize = $colInfo.result.config.params.vectors.size

    Write-Host "Colecao '$collectionName' encontrada com dimensao atual: $currentSize" -ForegroundColor Yellow

    if ($currentSize -eq $vectorSize -and -not $ForceRecreate) {
        Write-Host "A colecao ja esta perfeitamente configurada para $Provider ($vectorSize dimensoes)." -ForegroundColor Green
        Write-Host "Status: $($colInfo.status), Vetores: $($colInfo.result.vectors_count)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "A dimensao atual ($currentSize) difere da necessaria para $Provider ($vectorSize) ou foi solicitado -ForceRecreate." -ForegroundColor Yellow
        Write-Host "Excluindo colecao antiga para recriar..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Delete | Out-Null
        $needsCreation = $true
    }
} catch {
    Write-Host "Colecao '$collectionName' ainda nao existe. Criando agora..." -ForegroundColor Cyan
}

if ($needsCreation) {
    $body = @{
        vectors = @{
            size = $vectorSize
            distance = "Cosine"
        }
    } | ConvertTo-Json

    try {
        $create = Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Put -Body $body -ContentType "application/json"
        Write-Host "Colecao '$collectionName' criada com sucesso para $Provider ($vectorSize dimensoes)!" -ForegroundColor Green
        Write-Host ($create | ConvertTo-Json -Depth 3)
    } catch {
        Write-Host "Falha ao criar colecao no Qdrant: $_" -ForegroundColor Red
        exit 1
    }
}
