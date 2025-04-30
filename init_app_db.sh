#!/bin/bash
set -e

# Cria usuario e banco da app
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE ${APP_DB_NAME};
  CREATE USER ${APP_DB_USER} WITH PASSWORD '${APP_DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON DATABASE ${APP_DB_NAME} TO ${APP_DB_USER};
EOSQL

# Cria tabelas e politicas no banco da app
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$APP_DB_NAME" <<-EOSQL

  -- Cria tabela empresa
  CREATE TABLE IF NOT EXISTS empresa (
    id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    telefonewhatsapp VARCHAR,
    apikeybot VARCHAR,
    tokeninstance VARCHAR,
    status VARCHAR,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );

  -- Cria tabela clientes
  CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL,
    telefonewhatsapp VARCHAR,
    ativo VARCHAR,
    conversationid VARCHAR,
    idempresa INTEGER REFERENCES empresa(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );

  -- Ativa RLS
  ALTER TABLE empresa ENABLE ROW LEVEL SECURITY;
  ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

  -- Politica para empresa
  CREATE POLICY allow_all_access_empresa ON empresa
    FOR ALL TO public
    USING (true) WITH CHECK (true);

  -- Politica para clientes
  CREATE POLICY allow_all_access_clientes ON clientes
    FOR ALL TO public
    USING (true) WITH CHECK (true);

EOSQL
