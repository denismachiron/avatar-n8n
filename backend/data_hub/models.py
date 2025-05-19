import uuid
from django.db import models

class Empresa(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nome = models.CharField(max_length=255)
    telefone_whatsapp = models.CharField(max_length=30, unique=True)
    apikeybot = models.CharField(max_length=100, unique=True)
    tokeninstance = models.CharField(max_length=100, blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'hub_empresa'
        verbose_name_plural = 'Empresas'

    def __str__(self):
        return self.nome


class Cliente(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nome = models.CharField(max_length=255, blank=True)
    telefone_whatsapp = models.CharField(max_length=30)
    ativo = models.BooleanField(default=True)
    conversation_id = models.UUIDField(blank=True, null=True)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='clientes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'hub_clientes'
        verbose_name_plural = 'Clientes'

    def __str__(self):
        return self.nome or self.telefone_whatsapp


class Calendarios(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    empresa = models.ForeignKey('Empresa', on_delete=models.CASCADE)
    calendar_name = models.CharField(max_length=100)
    calendar_id = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'hub_calendarios'
    def __str__(self):
        return f"{self.empresa.nome} - {self.calendar_name}"
