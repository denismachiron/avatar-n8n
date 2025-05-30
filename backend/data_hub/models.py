import uuid
from django.db import models
import re 
from .services.evolution_api import EvolutionAPI
from django.conf import settings

def caminho_upload_conhecimento(instance, filename):
    return f"base_conhecimento/{instance.id}/{filename}"
class Empresa(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='empresas'
    )
    nome = models.CharField(max_length=255)
    telefone_whatsapp = models.CharField(max_length=30, unique=True)
    apikeybot = models.CharField(max_length=100, unique=True)
    tokeninstance = models.CharField(max_length=100, blank=True, null=True)
    status = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    arquivo_base_conhecimento = models.FileField(upload_to=caminho_upload_conhecimento, null=True, blank=True)
    qrcode_base64 = models.TextField(null=True, blank=True)
    class Meta:
        db_table = 'hub_empresa'
        verbose_name_plural = 'Empresas'

    def __str__(self):
        return self.nome

    def iniciar_instancia_evolution(self):
        print("Chamando iniciar_instancia_evolution()")
        api = EvolutionAPI()
        response = api.start_instance(
            instance_name=self.nome.lower().replace(" ", "_"), 
            number=re.sub(r'\D', '', self.telefone_whatsapp.split("@")[0]),
            webhook_url=f"http://auto.machiron.com.br:5678/webhook/db2ef305-ab11-450c-af04-e19183f8e8ee", #trocar depois
            events=["MESSAGES_UPSERT"]
        )
        
        if response and response.status_code == 201:
            data = response.json()
            qrcode_base64 = data.get("qrcode", {}).get("base64")
            self.status = "ativo"
            self.qrcode_base64 = qrcode_base64 
            self.save(update_fields=["status", "qrcode_base64"])
            return True
        else:
            self.status = "ERRO"
            self.save(update_fields=["status"])
            return False
    def conectar_instancia_evolution(self):
        print("[DEBUG] Chamando conectar_instancia_evolution()")
        api = EvolutionAPI()
        instance_name = self.nome.lower().replace(" ", "_")
        response = api.connect_instance(instance_name=instance_name)
        print(response, flush=True)
        if response and response.status_code == 200:
            data = response.json()
            print(data)
            qrcode_base64 = data.get("base64") or data.get("qrcode", {}).get("base64")
            if qrcode_base64:
                self.qrcode_base64 = qrcode_base64
                self.save(update_fields=["qrcode_base64"])
                print("[DEBUG] QR code atualizado com sucesso.")
                return True
            else:
                print("[DEBUG] Nenhum QR code retornado na resposta.")
                return False
        else:
            print("[ERROR] Erro ao conectar instância ou instância não encontrada.")
            self.status = "ERRO"
            self.save(update_fields=["status"])
            return False
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
