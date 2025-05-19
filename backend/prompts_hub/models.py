import uuid
from django.db import models
from django.utils import timezone

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
        # Se for setado como ativo, desativa os outros da mesma empresa/workflow/deploy
        if self.ativo:
            Prompt.objects.filter(
                empresa=self.empresa,
                workflow=self.workflow,
                ativo=True
            ).exclude(pk=self.pk).update(ativo=False)

        super().save(*args, **kwargs)


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