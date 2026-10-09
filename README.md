# Business WhatsApp AI RAG Chatbot

Este projeto permite criar um chatbot inteligente para WhatsApp utilizando RAG (Retrieval-Augmented Generation) com modelos do Google Gemini. Ele roda 100% no seu ambiente local (localhost) através de containers Docker.

## 🛠 Pré-requisitos

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando na sua máquina.
2. Chave de API do **Google Gemini** ativa (disponível gratuitamente via [Google AI Studio](https://aistudio.google.com/)).

---

## 🔑 Chaves de API e Credenciais do Projeto

Todas as chaves podem ser configuradas no arquivo `.env` (copiado a partir do `.env.example`). Abaixo está o detalhamento de cada uma das chaves utilizadas:

| Variável / Chave | Serviço | Finalidade | Status | Onde Configurar |
| :--- | :--- | :--- | :--- | :--- |
| **`GEMINI_API_KEY`** | Google Gemini (AI Studio) | Modelo de Chat e Inteligência Artificial (LLM). Modelo recomendado: `models/gemini-3-flash-preview`. | **Obrigatória** (Padrão) | Arquivo `.env` e Credencial no n8n |
| **`EVOLUTION_API_KEY`** | Evolution API | Autenticação global da Evolution API para criação de instâncias, QR Code e envio de mensagens WhatsApp. | **Obrigatória** (WhatsApp) | Arquivo `.env`, `docker-compose.yml` e Header no n8n |
| **`N8N_ENCRYPTION_KEY`** | n8n | Chave criptográfica interna para cifrar credenciais salvas no n8n e evitar perda de senhas ao recriar containers. | **Obrigatória** (Interna) | Arquivo `.env` e `docker-compose.yml` |
| **`QDRANT_API_KEY`** | Qdrant | Chave de autenticação do banco de dados vetorial para a base de conhecimento RAG. | **Opcional** (Localhost) | Arquivo `.env` e Credencial no n8n |
| **`OPENAI_API_KEY`** | OpenAI | Alternativa caso prefira utilizar modelos OpenAI (GPT-4o / Text Embeddings) no lugar do Gemini. | **Opcional** (Alternativa) | Arquivo `.env` e Credencial no n8n |
| **`WHATSAPP_TOKEN`** | Meta / WhatsApp Cloud | Token de acesso da Meta caso deseje usar a API Oficial do WhatsApp Cloud em vez da Evolution API. | **Opcional** (Meta Oficial) | Arquivo `.env` |
| **`WHATSAPP_PHONE_NUMBER_ID`** | Meta / WhatsApp Cloud | ID do número de telefone registrado no painel da Meta for Developers. | **Opcional** (Meta Oficial) | Arquivo `.env` |
| **`WHATSAPP_VERIFY_TOKEN`** | Meta / WhatsApp Cloud | Token secreto para validação do webhook oficial da Meta (ex: `meu_token_secreto_whatsapp_rag`). | **Opcional** (Meta Oficial) | Arquivo `.env` |

### Detalhes de Cada Chave

#### 1. `GEMINI_API_KEY` (Google Gemini)
* **Como obter:** Obtenha gratuitamente em [Google AI Studio](https://aistudio.google.com/app/apikey).
* **Uso:** Alimenta o nó **Google Gemini Chat Model** no n8n.
* **Modelo utilizado:** Utilize **`models/gemini-3-flash-preview`** para garantir respostas instantâneas e fugir dos bloqueios de cota (429) do plano gratuito.

#### 2. `EVOLUTION_API_KEY` (Evolution API)
* **Valor padrão do projeto:** `B42964AA252642248176A496FB14DF2A`
* **Uso:** Utilizada nos scripts PowerShell (`connect-evolution.ps1`, `test-evolution-webhook.ps1`) e no nó HTTP do n8n **"Send WhatsApp via Evolution"** (cabeçalho `apikey`).

#### 3. `N8N_ENCRYPTION_KEY` (n8n)
* **Valor padrão do projeto:** `c4f78e2289139ba8b991de2f4001b636`
* **Uso:** Chave estática fixa para garantir que o n8n consiga descriptografar suas credenciais cadastradas mesmo se você reiniciar ou recriar os containers Docker.

#### 4. `QDRANT_API_KEY` (Qdrant)
* **Valor padrão:** Deixada em branco por padrão para facilitar o uso no ambiente local (comunicação direta dentro da rede Docker `whatsapp-rag-net`).
* **Uso:** Necessária apenas se você publicar o Qdrant em um servidor externo protegido por senha.

---

## 🚀 Passo a Passo Definitivo para Inicializar o Projeto

### Passo 1: Subir a infraestrutura via Docker

Abra um terminal na pasta deste projeto e execute:
```bash
docker compose up -d
```
Isso fará o download das imagens (Evolution API, n8n, Qdrant, Redis e Postgres) e subirá todos os serviços.
*Nota técnica: O `docker-compose.yml` deste projeto já inclui a variável de ambiente `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`, essencial para permitir que os nós do n8n acessem variáveis nativas (como a Chave de API do Evolution).*

### Passo 2: Conectar o WhatsApp à Evolution API

Execute o script auxiliar para criar a instância e parear com seu WhatsApp:
```powershell
.\connect-evolution.ps1
```
A página abrirá no navegador. Leia o **QR Code** no seu WhatsApp -> Aparelhos Conectados.

### Passo 3: Acessar o n8n e Importar o Fluxo

1. Acesse o **n8n**: [http://localhost:5678](http://localhost:5678) (crie seu login/senha no primeiro acesso).
2. Vá em **Workflows** -> **Add Workflow**.
3. No canto superior direito, clique em `...` e escolha **Import from File**.
4. Importe o arquivo `workflow-whatsapp-evolution-gemini.json`.

### Passo 4: Configurações Vitais do Fluxo (Evitando Erros)

Ao importar o fluxo, 3 configurações exigem atenção estrita para que funcione "de primeira":

#### 1. Credencial e Modelo Correto do Google Gemini
As chaves do Gemini (especialmente em contas gratuitas novas) impõem limites severos a modelos antigos. 
Se você utilizar `gemini-1.5-pro` ou `gemini-2.5-pro`, poderá enfrentar o erro `404 Not Found` ou `429 Quota Exceeded (limit: 0)`.
* **Como corrigir:** Em todos os nós do tipo "Google Gemini Chat Model", escolha sempre a versão recomendada para este projeto: **`models/gemini-3-flash-preview`** (que possui cota gratuita e é super rápida e inteligente).

#### 2. Formatação do Payload de Retorno no Node HTTP (Evolution API)
O nó de HTTP Request chamado **"Send WhatsApp via Evolution"** envia a resposta gerada pela IA de volta para o Evolution API via JSON.
Se a IA devolver uma resposta contendo aspas ou quebras de linha e o JSON tiver sido montado manualmente, o n8n acusará o erro: `Bad control character in string literal in JSON`.
* **Como corrigir (Garantia de 100% de Sucesso):**
  1. Vá até o campo **Body** desse nó.
  2. Garanta que a aba ao lado direito seja **"Expression"** (e não "Fixed").
  3. Cole o seguinte código Javascript, que força o n8n a processar todo o objeto como um JSON válido em modo de execução, blindando-o contra caracteres que quebram o código:
  ```javascript
  {{
    JSON.stringify({
      "number": $('Filter Message').item.json.senderNumber,
      "text": $json.output
    })
  }}
  ```

### Passo 5: Alimentar a Base de Conhecimento (RAG)

1. Para que a IA saiba sobre a sua empresa, nós utilizamos o nó **RAG (Qdrant)** e os de processamento de texto. 
2. Os dados locais (como arquivos `.txt` ou `.pdf`) ficam na pasta local `./knowledge-base/` (mapeada dentro do n8n para `/data/knowledge-base/`).
3. Para ingerir dados iniciais, utilize a rota superior no n8n (Criação de Coleção e leitura de arquivos -> Qdrant (Insert)). Acione-os manualmente uma vez com o botão **Execute Node**.

### Passo 6: O Segredo Final - Ativação Correta do Webhook

Depois de tudo configurado e após qualquer "restart" do servidor n8n (docker restart), a memória interna das rotas dos Webhooks do n8n precisa ser recriada.
1. Salve o Workflow (botão **Save**).
2. Se a chavinha (canto superior direito) já estiver em **Active**, mude-a para **Inactive**.
3. Imediatamente, **Ative-a novamente (Active)**. 

Essa simples ação desativa e registra novamente a URL pública no servidor n8n, resolvendo os problemas como erro de servidor local ou `Cannot POST`.

Feito isso, mande uma mensagem pelo WhatsApp. Aproveite seu bot RAG de alta fidelidade!

## 💡 Dicas de Manutenção

- Para visualizar os logs da conexão do WhatsApp (caso algo dê erro): `docker logs whatsapp-rag-evolution -f`
- Para reiniciar toda a estrutura do zero: `docker compose down -v` (Isso apaga todos os dados de banco e conexões! Use com cautela).
