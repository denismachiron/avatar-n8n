from django.contrib import admin
from .models import Cliente,Empresa,Calendarios
from django.utils.html import format_html

@admin.register(Empresa)
class EmpresaAdmin(admin.ModelAdmin):
    list_display = ["nome", "telefone_whatsapp", "status"]
    readonly_fields = ["preview_qrcode"]
    actions = ["iniciar_instancia_evolution_action", "conectar_instancia_evolution_action"]

    def conectar_instancia_evolution_action(self, request, queryset):
        for empresa in queryset:
            empresa.conectar_instancia_evolution()
        self.message_user(request, "Conexão com instância solicitada com sucesso.")
    def iniciar_instancia_evolution_action(self, request, queryset):
        print("[DEBUG] Entrou na action do admin")
        for empresa in queryset:
            print(f"[DEBUG] Admin action chamada para: {empresa.nome}")
            empresa.iniciar_instancia_evolution()
        self.message_user(request, "Instância(s) iniciada(s) com sucesso.")

    def preview_qrcode(self, obj):
        if obj.qrcode_base64:
            return format_html('<img src="{}" width="300" />', obj.qrcode_base64)
        return "QR code ainda não gerado"
    
    preview_qrcode.short_description = "QR Code WhatsApp"

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(usuario=request.user)
@admin.register(Cliente)
class ClienteAdmin(admin.ModelAdmin):
    list_display = ['nome', 'telefone_whatsapp', 'empresa']

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(empresa__usuario=request.user)
        
admin.site.register(Calendarios)
