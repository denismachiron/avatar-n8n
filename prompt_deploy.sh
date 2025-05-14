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
: "${DB_CONTAINER:?Variável DB_CONTAINER não definida no .env}"

# === Step 1: Entradas ===
# === Step 3: Buscar ID do bot no banco ===
while true; do
    read -p "Digite o nome do cliente (exatamente como está no banco): " NOME_CLIENTE

    BOT_ID=$(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM $BOT_TABELA WHERE nome = '$NOME_CLIENTE';" | xargs)

    if [ -n "$BOT_ID" ]; then
        echo "✅ Cliente encontrado: ID = $BOT_ID"
        break
    fi

    echo -e "\n❌ Cliente '$NOME_CLIENTE' não encontrado na tabela '$BOT_TABELA'."
    echo "📋 Clientes disponíveis no banco:"
    sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT nome FROM $BOT_TABELA;"

    echo -e "\n🔁 Tente novamente ou use CTRL+C para cancelar."
done

echo "🔎 Client ID: $BOT_ID"

read -p "Digite o nome do workflow: " NOME_WORKFLOW

PASTA_PROMPT="prompts/${NOME_WORKFLOW}/${NOME_CLIENTE}"
PASTA_WORKFLOW="prompts/${NOME_WORKFLOW}"
if [ ! -d "$PASTA_WORKFLOW" ]; then
    echo -e "\n❌ Workflow '$NOME_WORKFLOW' não encontrado em 'prompts/'."
    echo "📂 Workflows disponíveis:"
    ls -1 prompts/
    
    echo -e "\nℹ️ Cancelando o deploy. Verifique o nome e tente novamente."
    exit 1
fi
read -p "Digite o nome do deploy (slug do prompt, ex: atendimento_vip): " NOME_DEPLOY
read -p "Digite uma breve descrição do deploy: " DESCRICAO_DEPLOY

# === Step 2: Caminho e arquivos ===

ARQUIVO_CHANGELOG="$PASTA_PROMPT/changelog.md"

# === Step 2.1: Prompt staging ===
STAGING_FILE="prompt_staging.txt"
DEPLOYED_FILE="$PASTA_PROMPT/prompt_deployed.txt"

# === Criar ou reutilizar prompt_staging.txt ===
STAGING_PATH="$PASTA_PROMPT/prompt_staging.txt"

if [ ! -f "$STAGING_PATH" ]; then
    echo "📝 Criando arquivo de staging: $STAGING_PATH"
    touch "$STAGING_PATH"
fi

echo -e "\n✏️  Abrindo o arquivo de staging para edição. Cole ou edite o conteúdo do prompt:"
sleep 1
nano "$STAGING_PATH"

# === Step 2.2: Criar arquivo de histórico no repositório ===
HISTORICO_PROMPT="$PASTA_PROMPT/${NOME_WORKFLOW}_${NOME_DEPLOY}.txt"
cp "$STAGING_PATH" "$HISTORICO_PROMPT"
echo "📦 Copiado '$STAGING_PATH' para '$HISTORICO_PROMPT' (versão de histórico)."

# === Step 2.3: Confirmação antes do deploy ===
read -p "⚠️ Deseja confirmar e realizar o deploy desse prompt? (s/N) " CONFIRMA_DEPLOY

if [[ "$CONFIRMA_DEPLOY" != "s" && "$CONFIRMA_DEPLOY" != "S" ]]; then
    echo "❌ Deploy cancelado."
    exit 1
fi

# === Step 2.4: Renomear staging para deployed ===
mv "$STAGING_PATH" "$DEPLOYED_FILE"
echo "✅ '$STAGING_FILE' renomeado para '$DEPLOYED_FILE'"



# === Step 4: Commit message padronizada ===
COMMIT_MSG="prompt_update: $NOME_DEPLOY, description: $DESCRICAO_DEPLOY, cliente_id: $BOT_ID"

# === Step 5: Atualizar changelog ===
{
  echo -e "## [$(date +%Y-%m-%d)] - $(whoami)"
  echo "- $DESCRICAO_DEPLOY"
  echo ""
} >> "$ARQUIVO_CHANGELOG"

echo "📘 Changelog atualizado."

# === Step 6: Git versionamento ===
git add "$HISTORICO_PROMPT" "$ARQUIVO_CHANGELOG" "$DEPLOYED_FILE"
git commit -m "$COMMIT_MSG"

# Garantir que estamos na branch correta
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "feat/prompt_manage" ]; then
    echo "🔀 Mudando para a branch feat/prompt_manage..."
    git checkout feat/prompt_manage
fi

git push origin feat/prompt_manage
echo "🚀 Deploy finalizado com sucesso na branch feat/prompt_manage."
