# avatar-n8n
Acesso ao banco
    sudo docker exec -it avatar-n8n_postgres_11 psql -U machiron -d machiron_avatar
sudo docker exec -it avatar-n8n_redis_1 redis-cli replicaof no one

 INSERT INTO empresa (
    nome,
    telefonewhatsapp,
    apikeybot,
    tokeninstance,
    status,
    created_at
) VALUES (
    'thiago',
    '5538992064324@s.whatsapp.net',
    'app-tZDuZvY4VZDSEfhvbRatbZW5',
    '', 
    'ativo',
    NOW()
);

machiron_avatar=# -- Cria tabela de agendamentos com SERIAL (relacionando com clientes e empresas)
CREATE TABLE IF NOT EXISTS agendamentos (
    id SERIAL PRIMARY KEY,
    idcliente INTEGER REFERENCES clientes(id),
    idempresa INTEGER REFERENCES empresa(id),
    email VARCHAR,
    data DATE,
    hora TIME,
    local VARCHAR,
    assunto VARCHAR,
    completo BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE
machiron_avatar=# ALTER TABLEE agendamentos ENABLE ROW LEVEL SECURITY;
ERROR:  syntax error at or near "TABLEE"
LINE 1: ALTER TABLEE agendamentos ENABLE ROW LEVEL SECURITY;
              ^
machiron_avatar=# ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE
machiron_avatar=# CREATE POLICY allow_all_access_agendamentos ON agendamentos
    FOR ALL TO public
    USING (true) WITH CHECK (true);