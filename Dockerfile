# Usando a imagem oficial da Evolution API
FROM atendai/evolution-api:v2.2.0

# Variáveis de ambiente
ENV AUTHENTICATION_API_KEY=jXbFjC7w2vOuQRJRawsKuNGNL5BloMpj

# Expondo a porta da aplicação
EXPOSE 8080

# Comando para iniciar a API
CMD ["npm", "run", "start:prod"]