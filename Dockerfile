# Dockerfile
FROM python:3.11

WORKDIR /app

# Copier le code de l'application
COPY . /app

# Installer pytest (et autres dépendances si besoin)
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install pytest

# Commande par défaut (juste un exemple)
CMD ["python3", "app.py"]
