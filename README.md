# avatar-n8n
Acesso ao banco
    sudo docker exec -it avatar-n8n_postgres_1 psql -U machiron -d machiron_avatar
sudo docker exec -it avatar-n8n_redis_1 redis-cli replicaof no one
sudo chown -R ubuntu:ubuntu /home/ubuntu/avatar-n8n/backend
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

CREATE TABLE IF NOT EXISTS workflows (
    id SERIAL PRIMARY KEY,
    idempresa INTEGER REFERENCES empresa(id),
    nome_fluxo VARCHAR,
    prompt_name VARCHAR,
    prompt_description VARCHAR,
    prompt_path VARCHAR,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
machiron_avatar=# ALTER TABLEE agendamentos ENABLE ROW LEVEL SECURITY;
ERROR:  syntax error at or near "TABLEE"
LINE 1: ALTER TABLEE agendamentos ENABLE ROW LEVEL SECURITY;
              ^
machiron_avatar=# ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE
machiron_avatar=# CREATE POLICY allow_all_access_agendamentos ON agendamentos
    FOR ALL TO public
    USING (true) WITH CHECK (true);

    ALTER TABLE workflows ENABLE ROW LEVEL SECURITY; 
    CREATE POLICY allow_all_access_workflows ON workflows
    FOR ALL TO public
    USING (true) WITH CHECK (true);


CREATE TABLE calendarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id INT NOT NULL,
    calendar_name VARCHAR NOT NULL,
    calendar_id VARCHAR NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    FOREIGN KEY (empresa_id) REFERENCES empresa(id) ON DELETE CASCADE
);
    ALTER TABLE calendarios ENABLE ROW LEVEL SECURITY; 
    CREATE POLICY allow_all_access_calendarios ON calendarios
    FOR ALL TO public
    USING (true) WITH CHECK (true);

CREATE TABLE log_atendimentos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  evento JSONB,
  created_at TIMESTAMP DEFAULT now()
);   
 ALTER TABLE log_atendimentos ENABLE ROW LEVEL SECURITY; 
    CREATE POLICY allow_all_access_log_atendimentos ON log_atendimentos
    FOR ALL TO public
    USING (true) WITH CHECK (true);