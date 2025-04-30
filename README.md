# avatar-n8n
Acesso ao banco
    sudo docker exec -it avatar-n8n-postgres-1 psql -U machiron -d machiron_avatar
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