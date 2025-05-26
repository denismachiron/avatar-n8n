from django.core.management.base import BaseCommand
from prompts_hub.models import Prompt, PromptHistory


class Command(BaseCommand):
    help = 'Migrates all inactive prompts to PromptHistory if not already saved'

    def handle(self, *args, **options):
        migrated = 0
        skipped = 0

        inactive_prompts = Prompt.objects.filter(ativo=False)

        for prompt in inactive_prompts:
            exists = PromptHistory.objects.filter(original=prompt).exists()
            if exists:
                skipped += 1
                continue

            last_version = PromptHistory.objects.filter(original=prompt).order_by('-version_number').first()
            next_version = (last_version.version_number + 1) if last_version else 1

            PromptHistory.objects.create(
                original=prompt,
                empresa=prompt.empresa,
                workflow=prompt.workflow,
                nome_deploy=prompt.nome_deploy,
                descricao=prompt.descricao,
                prompt_text=prompt.prompt_text,
                input_schema=getattr(prompt, 'input_schema', None),
                ativo=prompt.ativo,
                version_number=next_version,
                criado_por='MIGRATION_SCRIPT'
            )
            migrated += 1

        self.stdout.write(self.style.SUCCESS(
            f"Migrated {migrated} inactive prompts to PromptHistory. Skipped {skipped} already migrated."
        ))
