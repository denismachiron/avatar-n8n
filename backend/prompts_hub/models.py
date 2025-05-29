import uuid
from django.db import models
from django.utils import timezone
from django.db import models
from django.db.models import JSONField
from django.conf import settings


class PromptHistory(models.Model):
    original = models.ForeignKey(
        'prompts_hub.Prompt',
        on_delete=models.CASCADE,
        related_name='historicos'
    )

    empresa = models.ForeignKey('data_hub.Empresa', on_delete=models.CASCADE)
    workflow = models.ForeignKey('prompts_hub.Workflow', on_delete=models.CASCADE)
    nome_deploy = models.CharField(max_length=255)
    descricao = models.TextField(blank=True)
    prompt_text = models.TextField()
    input_schema = models.JSONField(blank=True, null=True)
    ativo = models.BooleanField(default=False)
    version_number = models.PositiveIntegerField()
    criado_em = models.DateTimeField(default=timezone.now)
    criado_por = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        ordering = ['-criado_em']
        unique_together = ('original', 'version_number')

    def __str__(self):
        return f"v{self.version_number} de {self.original.nome_deploy} ({self.criado_em.date()})"

    def diff_with_previous(self):
        previous = PromptHistory.objects.filter(
            original=self.original,
            version_number=self.version_number - 1
        ).first()

        if not previous:
            return {"diff": "No previous version"}

        return {
            "prompt_text_diff": self.prompt_text != previous.prompt_text,
            "input_schema_diff": self.input_schema != previous.input_schema,
            "descricao_diff": self.descricao != previous.descricao,
        }

    def rollback(self):
        prompt = self.original
        prompt.prompt_text = self.prompt_text
        prompt.input_schema = self.input_schema
        prompt.descricao = self.descricao
        prompt.ativo = self.ativo
        prompt.save()
        return prompt
class Prompt(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    empresa = models.ForeignKey(
        'data_hub.Empresa', 
        on_delete=models.CASCADE,
        related_name='prompts'
    )

    workflow = models.ForeignKey(
        'prompts_hub.Workflow',
        on_delete=models.CASCADE,
        related_name='prompts'
    )
    nome_deploy = models.CharField(max_length=255)
    descricao = models.TextField(blank=True)
    prompt_text = models.TextField()  
    ativo = models.BooleanField(default=True)
    input_schema = models.JSONField(
        blank=True,
        null=True,
        help_text="Exemplo: {\"fields\": {\"nome\": {\"type\": \"string\"}, \"data_nascimento\": {\"type\": \"date\"}}}"
    )

    criado_em = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'hub_prompt_history'
        verbose_name_plural = 'Prompts'
        indexes = [
            models.Index(fields=["empresa", "workflow", "nome_deploy", "ativo"]),
        ]

    def __str__(self):
        return f"{self.empresa.nome} | {self.workflow} | {self.nome_deploy} | {'Ativo' if self.ativo else 'Inativo'}"

def save(self, *args, **kwargs):
    is_creating = not self._state.adding

    if is_creating:
        try:
            old = Prompt.objects.get(pk=self.pk)
            last_version = PromptHistory.objects.filter(original=self).order_by('-version_number').first()
            next_version = (last_version.version_number + 1) if last_version else 1

            PromptHistory.objects.create(
                original=self,
                empresa=old.empresa,
                workflow=old.workflow,
                nome_deploy=old.nome_deploy,
                descricao=old.descricao,
                prompt_text=old.prompt_text,
                input_schema=getattr(old, 'input_schema', None),
                ativo=old.ativo,
                version_number=next_version,
                criado_por='AUTO_VERSION'
            )
        except Prompt.DoesNotExist:
            pass  # Primeira criação, não há versão anterior

    super().save(*args, **kwargs)

    # Revalida o estado 'ativo' depois de salvo (garante que o objeto exista no banco)
    if self.ativo:
        Prompt.objects.filter(
            empresa=self.empresa,
            workflow=self.workflow,
            ativo=True
        ).exclude(pk=self.pk).update(ativo=False)



class Workflow(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nome = models.CharField(max_length=255, unique=True)
    descricao = models.TextField(blank=True)
    ativo = models.BooleanField(default=True)
    criado_em = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'hub_workflows'
        verbose_name_plural = 'Workflows'

    def __str__(self):
        return self.nome


class WorflowTestReview(models.Model):
    workflow = models.ForeignKey(
        'prompts_hub.Workflow',
        on_delete=models.CASCADE,
        related_name='test_reviews',
        help_text="Fluxo de onde vem o output analisado"
    )
    empresa = models.ForeignKey(
        'data_hub.Empresa',
        on_delete=models.CASCADE,
        related_name='test_reviews',
        help_text="Empresa de onde vem o output analisado"
    )
    msg = models.TextField(help_text="Mensagem original recebida pelo assistente")
    output = models.TextField(help_text="Resposta gerada pela IA")
    if_approval = models.BooleanField(default=False, help_text="A IA aprovou ou não?")
    
    #payload do fluxo
    ai_full_response = JSONField(help_text="JSON completo retornado pela IA")

    #revisão humana
    reviewed = models.BooleanField(default=False, help_text="Já revisado por um humano?")
    reviewer_comments = models.TextField(blank=True, null=True)
    reviewer_name = models.CharField(max_length=100, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.workflow}, {self.empresa}], Aprovado IA: {self.if_approval} | Revisado: {self.reviewed}"

class HumanReview(models.Model):
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        help_text="Usuário do sistema que realizou a revisão"
    )
    prompt_review = models.ForeignKey(
        'prompts_hub.Prompt',
        on_delete=models.CASCADE,
        related_name='human_reviews_from_prompt',
        help_text="Prompt que foi revisado manualmente"
    )
    sucesso_final = models.BooleanField(
        default=False,
        help_text="O objetivo final do usuário foi atingido? Ex: agendar, remarcar, etc."
    )

    qualidade_respostas = models.IntegerField(
        choices=[(i, f"{i}/5") for i in range(1, 6)],
        default=3,
        help_text="Nota geral para as respostas da IA (completude, clareza, coerência)"
    )

    houve_ruidos = models.BooleanField(
        default=False,
        help_text="Houve partes da conversa onde a IA demonstrou ruído ou má interpretação?"
    )

    comentario_geral = models.TextField(
        blank=True,
        null=True,
        help_text="Comentários adicionais sobre o comportamento da IA no caso analisado"
    )

    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-criado_em']

    def __str__(self):
        return f"Revisão de  por {self.reviewer} | Sucesso: {self.sucesso_final}"
