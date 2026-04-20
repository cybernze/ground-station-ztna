# ── Etapa base ────────────────────────────────────────────────────────────────
# Imagen oficial Python slim — pequeña, sin bloat
FROM python:3.12-slim

# ── Metadatos ─────────────────────────────────────────────────────────────────
LABEL maintainer="ground-station-operator"
LABEL description="Ground Station Telecommand API — Zero Trust demo"

# ── Usuario no-root ────────────────────────────────────────────────────────────
# Seguridad: nunca correr como root dentro del contenedor
RUN useradd --create-home --shell /bin/bash gsoperator

# ── Directorio de trabajo ──────────────────────────────────────────────────────
WORKDIR /app

# ── Dependencias ──────────────────────────────────────────────────────────────
# Copiamos requirements primero — Docker cachea esta capa si no cambia
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Código fuente ──────────────────────────────────────────────────────────────
COPY main.py .

# ── Permisos ──────────────────────────────────────────────────────────────────
RUN chown -R gsoperator:gsoperator /app
USER gsoperator

# ── Exposición de puerto ───────────────────────────────────────────────────────
# 8000 interno — Nginx (Fase 4) hará proxy desde 8443
EXPOSE 8000

# ── Comando de arranque ────────────────────────────────────────────────────────
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
