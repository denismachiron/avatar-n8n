from django.db import models
from pgvector.django import VectorField

class ChunkEmbedding(models.Model):
    empresa = models.ForeignKey('data_hub.Empresa', on_delete=models.CASCADE, related_name='chunks')
    ordem = models.IntegerField()
    texto = models.TextField()
    embedding = VectorField(dimensions=1536)

    class Meta:
        indexes = [
            models.Index(fields=['empresa']),
        ]
