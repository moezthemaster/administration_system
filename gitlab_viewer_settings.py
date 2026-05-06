import os
from dotenv import load_dotenv
from pathlib import Path

# Charge .env depuis le dossier courant
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

# Configuration GitLab
GITLAB_URL = os.getenv("GITLAB_URL", "https://gitlab.com")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN")
GITLAB_BRANCH = os.getenv("GITLAB_BRANCH", "main")

# Configuration API
API_TOKEN = os.getenv("API_TOKEN")
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))

# Désactivation SSL (True pour désactiver, False pour activer)
GITLAB_VERIFY_SSL = os.getenv("GITLAB_VERIFY_SSL", "False").lower() == "true"

# Mapping environnement -> hostname et project_id
ENV_CONFIG = {
    "dev": {
        "hostname": "lxdv01",
        "project_id": "335"
    },
    "proto": {
        "hostname": "lxdproto01",
        "project_id": "331"
    },
    "homol_primaire": {
        "hostname": "lxhomol1",
        "project_id": "345"
    },
    "homol_secours": {
        "hostname": "lxhomol2",
        "project_id": "345"
    },
    "prod_primaire": {
        "hostname": "lxprod1",
        "project_id": "327"
    },
    "prod_secours": {
        "hostname": "lxprod2",
        "project_id": "327"
    },
}

# Fichiers disponibles
AVAILABLE_FILES = ["wildfly.yml", "jboss.yaml"]
