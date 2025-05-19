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
: "${DB_CONTAINER:?Variável DB_CONTAINER não definida no .env}"

# === Step 1: Buscar e listar empresas ===
echo "🔎 Buscando empresas na tabela 'empresa'..."

EMPRESAS=$(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT nome FROM empresa ORDER BY nome;")

mapfile -t EMPRESAS_ARR < <(echo "$EMPRESAS" | sed '/^\s*$/d')

if [ ${#EMPRESAS_ARR[@]} -eq 0 ]; then
    echo "❌ Nenhuma empresa encontrada na tabela 'empresa'."
    exit 1
fi

echo "📋 Empresas encontradas:"
for i in "${!EMPRESAS_ARR[@]}"; do
    echo "[$((i+1))] ${EMPRESAS_ARR[$i]}"
done

# === Step 2: Usuário escolhe a empresa pelo número ===
while true; do
    read -p "Digite o número da empresa desejada: " EMPRESA_IDX

    if [[ "$EMPRESA_IDX" =~ ^[0-9]+$ ]] && [ "$EMPRESA_IDX" -ge 1 ] && [ "$EMPRESA_IDX" -le ${#EMPRESAS_ARR[@]} ]; then
        NOME_CLIENTE="$(echo "${EMPRESAS_ARR[$((EMPRESA_IDX-1))]}" | xargs)"
        echo "✅ Empresa selecionada:$NOME_CLIENTE"

        BOT_ID=$(sudo docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM empresa WHERE nome = '$NOME_CLIENTE';" | xargs)

        if [ -z "$BOT_ID" ]; then
            echo "❌ Não foi possível encontrar o ID da empresa '$NOME_CLIENTE'."
            exit 1
        fi

        echo "🔎 ID do cliente: $BOT_ID"
        break
    else
        echo "❌ Número inválido. Tente novamente."
    fi
done

# === Step 3: Escolher workflow ===
echo ""
echo "📂 Workflows disponíveis:"
ls -1 prompts/

read -p "Digite o nome do workflow: " NOME_WORKFLOW

PASTA_WORKFLOW="prompts/${NOME_WORKFLOW}"

if [ ! -d "$PASTA_WORKFLOW" ]; then
    echo "❌ Workflow '$NOME_WORKFLOW' não encontrado em 'prompts/'."
    exit 1
fi

# === Step 4: Criar pasta prompt para o cliente dentro do workflow ===
PASTA_PROMPT="${PASTA_WORKFLOW}/${NOME_CLIENTE}"

if [ ! -d "$PASTA_PROMPT" ]; then
    echo "📁 Criando pasta para o cliente no workflow: $PASTA_PROMPT"
    mkdir -p "$PASTA_PROMPT"
fi

# === Step 5: Nome e descrição do deploy ===
read -p "Digite o nome do deploy (slug do prompt, ex: atendimento_vip): " NOME_DEPLOY
read -p "Digite uma breve descrição do deploy: " DESCRICAO_DEPLOY

# === Step 6: Preparar arquivos ===
STAGING_FILE="prompt_staging.txt"
DEPLOYED_FILE="$PASTA_PROMPT/prompt_deployed.txt"
STAGING_PATH="$PASTA_PROMPT/$STAGING_FILE"
HISTORICO_PROMPT="$PASTA_PROMPT/${NOME_WORKFLOW}_${NOME_DEPLOY}.txt"
ARQUIVO_CHANGELOG="$PASTA_PROMPT/changelog.md"

if [ ! -f "$STAGING_PATH" ]; then
    echo "📝 Criando arquivo de staging: $STAGING_PATH"
    touch "$STAGING_PATH"
fi

echo -e "\n✏️ Abrindo arquivo de staging para edição (vim):"
sleep 1
vim "$STAGING_PATH"

cp "$STAGING_PATH" "$HISTORICO_PROMPT"
echo "📦 Copiado '$STAGING_PATH' para '$HISTORICO_PROMPT' (versão de histórico)."

read -p "⚠️ Deseja confirmar e realizar o deploy desse prompt? (s/N) " CONFIRMA_DEPLOY

if [[ "$CONFIRMA_DEPLOY" != "s" && "$CONFIRMA_DEPLOY" != "S" ]]; then
    echo "❌ Deploy cancelado."
    exit 1
fi

mv "$STAGING_PATH" "$DEPLOYED_FILE"
echo "✅ '$STAGING_FILE' renomeado para '$DEPLOYED_FILE'"

{
  echo -e "## [$(date +%Y-%m-%d)] - $(whoami)"
  echo "- $DESCRICAO_DEPLOY"
  echo ""
} >> "$ARQUIVO_CHANGELOG"

echo "📘 Changelog atualizado."

COMMIT_MSG="prompt_update: $NOME_DEPLOY, description: $DESCRICAO_DEPLOY, cliente_id: $BOT_ID"

git add "$HISTORICO_PROMPT" "$ARQUIVO_CHANGELOG" "$DEPLOYED_FILE"
git commit -m "$COMMIT_MSG"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "feat/prompt_manage" ]; then
    echo "🔀 Mudando para a branch feat/prompt_manage..."
    git checkout feat/prompt_manage
fi

git push origin feat/prompt_manage
echo "🚀 Deploy finalizado com sucesso na branch feat/prompt_manage."
