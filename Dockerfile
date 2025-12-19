# Dockerfile
FROM python:3.11

# Créer un environnement virtuel dans /opt/venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Définir le répertoire de travail
WORKDIR /app

# Copier le code de l'application
COPY . /app

# Installer les dépendances dans le venv
RUN pip install --upgrade pip
RUN pip install pytest

# Exposer un port si nécessaire (ex: pour une API)
# EXPOSE 5000

# Commande par défaut pour lancer l'application
CMD ["python3", "app.py"]

