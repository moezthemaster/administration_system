import os
from dotenv import load_dotenv

load_dotenv()

# GitLab configuration
GITLAB_URL = os.getenv("GITLAB_URL", "https://gitlab.com")
PROJECT_ID = os.getenv("PROJECT_ID")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN")
GITLAB_BRANCH = os.getenv("GITLAB_BRANCH", "main")

# API configuration
API_TOKEN = os.getenv("API_TOKEN")
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))

# Environment mapping
ENV_HOSTNAME_MAPPING = {
    "dev": "lxdv01",
    "homol": "lxdv02",
    "prod": "lxdprod01",
}

# Available files
AVAILABLE_FILES = ["wildfly.yml", "jboss.yaml"]
