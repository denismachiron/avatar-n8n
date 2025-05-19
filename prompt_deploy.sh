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

# === Listar empresas disponíveis ===
echo "📋 Empresas disponíveis:"
EMPRESAS=($(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT nome FROM $BOT_TABELA;" | xargs -n1))
for i in "${!EMPRESAS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${EMPRESAS[$i]}"
done

while true; do
    read -p "Selecione o número da empresa: " EMPRESA_IDX
    if [[ "$EMPRESA_IDX" =~ ^[0-9]+$ && "$EMPRESA_IDX" -ge 1 && "$EMPRESA_IDX" -le "${#EMPRESAS[@]}" ]]; then
        NOME_CLIENTE="$(echo "${EMPRESAS[$((EMPRESA_IDX-1))]}" | xargs)"
        BOT_ID=$(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM $BOT_TABELA WHERE nome = '$NOME_CLIENTE';" | xargs)
        if [ -n "$BOT_ID" ]; then
            echo "✅ Cliente selecionado: $NOME_CLIENTE (ID: $BOT_ID)"
            break
        else
            echo "❌ Não foi possível encontrar o ID da empresa '$NOME_CLIENTE'"
        fi
    else
        echo "⚠️ Número inválido. Tente novamente."
    fi
done

# === Listar workflows ===
echo "📂 Workflows disponíveis:"
WORKFLOWS=($(ls -1 prompts))
for i in "${!WORKFLOWS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${WORKFLOWS[$i]}"
done

while true; do
    read -p "Selecione o número do workflow: " WF_IDX
    if [[ "$WF_IDX" =~ ^[0-9]+$ && "$WF_IDX" -ge 1 && "$WF_IDX" -le "${#WORKFLOWS[@]}" ]]; then
        NOME_WORKFLOW="${WORKFLOWS[$((WF_IDX-1))]}"
        break
    else
        echo "⚠️ Número inválido. Tente novamente."
    fi
done

PASTA_PROMPT="prompts/${NOME_WORKFLOW}/${NOME_CLIENTE}"
PASTA_WORKFLOW="prompts/${NOME_WORKFLOW}"

mkdir -p "$PASTA_PROMPT"

read -p "Digite o nome do deploy (slug do prompt, ex: atendimento_vip): " NOME_DEPLOY
read -p "Digite uma breve descrição do deploy: " DESCRICAO_DEPLOY

ARQUIVO_CHANGELOG="$PASTA_PROMPT/changelog.md"
STAGING_FILE="prompt_staging.txt"
DEPLOYED_FILE="$PASTA_PROMPT/prompt_deployed.txt"
STAGING_PATH="$PASTA_PROMPT/$STAGING_FILE"

if [ ! -f "$STAGING_PATH" ]; then
    echo "📝 Criando arquivo de staging: $STAGING_PATH"
    touch "$STAGING_PATH"
fi

echo -e "\n✏️  Abrindo o arquivo de staging para edição:"
sleep 1
nano "$STAGING_PATH"

HISTORICO_PROMPT="$PASTA_PROMPT/${NOME_WORKFLOW}_${NOME_DEPLOY}.txt"
cp "$STAGING_PATH" "$HISTORICO_PROMPT"
echo "📦 Copiado '$STAGING_PATH' para '$HISTORICO_PROMPT' (versão de histórico)."

read -p "⚠️ Deseja confirmar e realizar o deploy desse prompt? (s/N) " CONFIRMA_DEPLOY
if [[ "$CONFIRMA_DEPLOY" != "s" && "$CONFIRMA_DEPLOY" != "S" ]]; then
    echo "❌ Deploy cancelado."
    exit 1
fi

mv "$STAGING_PATH" "$DEPLOYED_FILE"
echo "✅ '$STAGING_FILE' renomeado para '$DEPLOYED_FILE'"

COMMIT_MSG="prompt_update: $NOME_DEPLOY, description: $DESCRICAO_DEPLOY, cliente_id: $BOT_ID"

{
  echo -e "## [$(date +%Y-%m-%d)] - $(whoami)"
  echo "- $DESCRICAO_DEPLOY"
  echo ""
} >> "$ARQUIVO_CHANGELOG"
echo "📘 Changelog atualizado."

git add "$HISTORICO_PROMPT" "$ARQUIVO_CHANGELOG" "$DEPLOYED_FILE"
git commit -m "$COMMIT_MSG"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "feat/prompt_manage" ]; then
    echo "🔀 Mudando para a branch feat/prompt_manage..."
    git checkout feat/prompt_manage
fi

git push origin feat/prompt_manage
echo "🚀 Deploy finalizado com sucesso na branch feat/prompt_manage."
