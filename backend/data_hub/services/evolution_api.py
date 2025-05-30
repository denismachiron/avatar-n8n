# yourapp/services/evolution_api.py
import requests
from django.conf import settings

AUTHENTICATION_API_KEY='jXbFjC7w2vOuQRJRawsKuNGNL5BloMpj'

class EvolutionAPI:
    def __init__(self):
        self.base_url = settings.EVOLUTION_API_BASE_URL  
        self.default_headers = {
            "Content-Type": "application/json",
            "apikey": AUTHENTICATION_API_KEY,
        }

    def connect_instance(self, instance_name):
        try:
            print(f"[DEBUG] Conectando instância: {instance_name}")
            response = requests.get(
                f"{self.base_url}/instance/connect/{instance_name}",
                headers=self.default_headers,
                timeout=10
            )
            print("[DEBUG] Resposta connect_instance:", response.status_code)
            return response
        except requests.RequestException as e:
            print(f"[ERROR] Erro ao conectar instância {instance_name}: {e}")
            return None
    def start_instance(self, instance_name, number, webhook_url, events=None):
        print('iniciando instancia')
        payload = {
            "instanceName": instance_name,
            "number": number,
            "qrcode": True,
            "integration": "WHATSAPP-BAILEYS",
            "webhook": {
                "url": webhook_url,
                "byEvents": False,
                "base64": True,
                "events": events or ["MESSAGES_UPSERT"]
            }
        }
        print(payload)
        try:
            response = requests.post(
                f"{self.base_url}/instance/create",
                json=payload,
                headers=self.default_headers,
                timeout=10
            )
            print(response)
            return response
        except requests.RequestException as e:
            return None  # ou raise, dependendo do seu tratamento
