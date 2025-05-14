#!/bin/bash

set -e

# === Carregar variáveis do .env ===
ENV_PATH="$(dirname "$0")/.env"

if [ -f "$ENV_PATH" ]; then
    echo "🔧 Carregando variáveis do $ENV_PATH"
    export $(grep -v '^#' "$ENV_PATH" | xargs)
else
    echo "❌ Arquivo .env não encontrado em: $ENV_PATH"
    exit 1
fi

# === Validar variáveis obrigatórias ===
: "${DB_USER:?Variável DB_USER não definida no .env}"
: "${DB_NAME:?Variável DB_NAME não definida no .env}"
: "${DB_HOST:?Variável DB_HOST não definida no .env}"
: "${DB_PORT:?Variável DB_PORT não definida no .env}"
: "${BOT_TABELA:?Variável BOT_TABELA não definida no .env}"

# === Step 1: Entradas ===
read -p "Digite o nome do workflow: " NOME_WORKFLOW
read -p "Digite o nome do deploy (slug do prompt, ex: atendimento_vip): " NOME_DEPLOY
read -p "Digite uma breve descrição do deploy: " DESCRICAO_DEPLOY
read -p "Nome do cliente que utilizará esse prompt: " NOME_CLIENTE

# === Step 2: Caminho e arquivos ===
PASTA_PROMPT="prompts/${NOME_WORKFLOW}"
ARQUIVO_PROMPT="$PASTA_PROMPT/${NOME_DEPLOY}.txt"

if [ ! -d "$PASTA_PROMPT" ]; then
    echo -e "\n❌ Workflow '$NOME_WORKFLOW' não encontrado em 'prompts/'."
    echo "📂 Workflows disponíveis:"
    ls -1 prompts/
    
    echo -e "\nℹ️ Cancelando o deploy. Verifique o nome e tente novamente."
    exit 1
fi

ARQUIVO_CHANGELOG="$PASTA_PROMPT/changelog.md"

# === Step 3: Criar prompt se não existir ===
if [ ! -f "$ARQUIVO_PROMPT" ]; then
    echo "# Novo prompt: $NOME_DEPLOY" > "$ARQUIVO_PROMPT"
    echo "✅ Criado: $ARQUIVO_PROMPT"
else
    echo "ℹ️ Já existe: $ARQUIVO_PROMPT"
fi



# === Step 4: Buscar ID do bot no banco ===
while true; do
    read -p "Digite o nome do bot (exatamente como está no banco): " NOME_CLIENTE

    BOT_ID=$(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM $BOT_TABELA WHERE nome = '$NOME_CLIENTE';" | xargs)

    if [ -n "$BOT_ID" ]; then
        echo "✅ Bot encontrado: ID = $BOT_ID"
        break
    fi

    echo -e "\n❌ Bot '$NOME_CLIENTE' não encontrado na tabela '$BOT_TABELA'."
    echo "📋 Bots disponíveis no banco:"
    sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT nome FROM $BOT_TABELA;"

    echo -e "\n🔁 Tente novamente ou use CTRL+C para cancelar."
done

echo "🔎 Bot ID: $BOT_ID"

# === Step 5: Commit message padronizada ===
COMMIT_MSG="prompt_update: $NOME_DEPLOY, description: $DESCRICAO_DEPLOY, cliente_id: $BOT_ID "

# === Step 6: Atualizar changelog ===
{
  echo -e "## [$(date +%Y-%m-%d)] - $(whoami)"
  echo "- $DESCRICAO_DEPLOY"
  echo ""
} >> "$ARQUIVO_CHANGELOG"

echo "📘 Changelog atualizado."

# === Step 7: Git versionamento ===
git add "$ARQUIVO_PROMPT" "$ARQUIVO_CHANGELOG"
git commit -m "$COMMIT_MSG"

# Garantir que estamos na branch correta
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "feat/prompt_manage" ]; then
    echo "🔀 Mudando para a branch feat/prompt_manage..."
    git checkout feat/prompt_manage
fi

git push origin feat/prompt_manage
echo "🚀 Deploy finalizado com sucesso na branch feat/prompt_manage."

