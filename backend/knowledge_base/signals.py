# myapp/signals.py

from django.db.models.signals import post_save
from django.dispatch import receiver
from data_hub.models import Empresa
import requests

N8N_WEBHOOK_URL = 'http://auto.machiron.com.br:5678/webhook/322239d0-faf8-4fa8-9c2a-fa56ac09bc8b'

@receiver(post_save, sender=Empresa)
def enviar_para_n8n(sender, instance, created, **kwargs):
    if not instance.arquivo_base_conhecimento:
        return

    try:
        with instance.arquivo_base_conhecimento.open('rb') as f:
            files = {'file': (f.name, f, 'application/pdf')}
            data = {
                'id': str(instance.id),
                'nome': instance.nome,
            }

            response = requests.post(
                N8N_WEBHOOK_URL,
                data=data,
                files=files,
                timeout=10,
            )
            response.raise_for_status()
    except Exception as e:
        print(f"Erro ao enviar para o n8n: {e}")