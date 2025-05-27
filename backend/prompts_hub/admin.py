from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
import json
from .models import Prompt ,Workflow,WorflowTestReview,PromptHistory,HumanReview
from django import forms
from django_json_widget.widgets import JSONEditorWidget
admin.site.register(HumanReview)

@admin.register(WorflowTestReview)
class WorflowTestReviewAdmin(admin.ModelAdmin):
    list_display = ('workflow','empresa', 'if_approval', 'reviewed', 'reviewer_name', 'created_at')
    list_filter = ('workflow', 'if_approval', 'reviewed')
    search_fields = ('msg', 'output', 'reviewer_name','empresa')
    readonly_fields = ('pretty_ai_response', 'msg', 'output', 'if_approval', 'created_at','empresa','workflow')

    fieldsets = (
        (None, {
            'fields': ('workflow','empresa', 'msg', 'output', 'if_approval', 'pretty_ai_response')
        }),
        ('Review', {
            'fields': ('reviewed', 'reviewer_name', 'reviewer_comments')
        }),
    )

    def pretty_ai_response(self, obj):
        try:
            pretty_json = json.dumps(obj.ai_full_response, indent=2, ensure_ascii=False)
        except Exception as e:
            return f"<pre>Error rendering JSON: {e}</pre>"

        return format_html('<pre style="max-height: 400px; overflow: auto; background: #037ffc;color:white; border: 1px solid #ddd;">{}</pre>', pretty_json)

    pretty_ai_response.short_description = "Resposta da IA (JSON Formatado)"


class PromptAdminForm(forms.ModelForm):
    class Meta:
        model = Prompt
        fields = '__all__'
        widgets = {
            'input_schema': JSONEditorWidget,
        }
@admin.register(Prompt)
class PromptAdmin(admin.ModelAdmin):
    form = PromptAdminForm
    list_display = ('empresa', 'workflow', 'nome_deploy', 'ativo', 'criado_em')
    readonly_fields = ('criado_em',)
    list_filter = ('empresa', 'workflow', 'ativo')
    search_fields = ('nome_deploy', 'descricao')

@admin.register(PromptHistory)
class PromptHistoryAdmin(admin.ModelAdmin):
    list_display = ('original', 'version_number', 'criado_em', 'criado_por', 'ativo')
    readonly_fields = (
        'original', 'empresa', 'workflow', 'nome_deploy',
        'descricao', 'prompt_text', 'input_schema',
        'ativo', 'version_number', 'criado_em', 'criado_por',
        'rollback_preview', 'diff_preview'
    )

    def rollback_preview(self, obj):
        return "Click 'Rollback to this version' below to restore."

    def diff_preview(self, obj):
        diff = obj.diff_with_previous()
        return str(diff)

    actions = ['rollback_to_selected_version']

    @admin.action(description="Rollback to selected version")
    def rollback_to_selected_version(self, request, queryset):
        for version in queryset:
            version.rollback()
            self.message_user(request, f"Rolled back to version {version.version_number} of {version.original}")


    fieldsets = (
        (None, {
            'fields': (
                'original', 'version_number', 'criado_em', 'criado_por'
            )
        }),
        ('Conteúdo do Prompt', {
            'fields': (
                'nome_deploy', 'descricao', 'prompt_text', 'input_schema', 'ativo'
            )
        }),
        ('Ações', {
            'fields': ('diff_preview', 'rollback_preview'),
        })
    )

