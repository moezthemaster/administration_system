from fastapi import FastAPI, HTTPException, Query
from typing import List, Optional
import httpx
import os
from enum import Enum

app = FastAPI(title="GitLab File Viewer API")

# Mapping environnement -> hostname
ENV_HOSTNAME_MAPPING = {
    "dev": "lxdv01",
    "homol": "lxdv02",  # À adapter
    "prod": "lxdprod01",  # À adapter
    # Ajoutez d'autres mappings selon vos besoins
}

# Liste des fichiers disponibles
AVAILABLE_FILES = ["wildfly.yml", "jboss.yaml"]

class Environnement(str, Enum):
    DEV = "dev"
    HOMOL = "homol"
    PROD = "prod"

class Fichier(str, Enum):
    WILDFLY = "wildfly.yml"
    JBOSS = "jboss.yaml"

# Configuration GitLab (à mettre dans des variables d'environnement)
GITLAB_URL = os.getenv("GITLAB_URL", "https://gitlab.com")
PROJECT_ID = os.getenv("PROJECT_ID", "123456")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN", "votre_token")
GITLAB_BRANCH = os.getenv("GITLAB_BRANCH", "main")

@app.get("/fichier-git")
async def get_file_from_git(
    environnement: Environnement,
    fichier: Fichier
):
    """
    Récupère un fichier depuis GitLab selon l'environnement et le type de fichier
    
    - **environnement**: dev, homol, prod
    - **fichier**: wildfly.yml, jboss.yaml
    """
    
    # Récupérer le hostname correspondant à l'environnement
    hostname = ENV_HOSTNAME_MAPPING.get(environnement.value)
    if not hostname:
        raise HTTPException(
            status_code=400, 
            detail=f"Environnement '{environnement}' non reconnu"
        )
    
    # Construire le chemin du fichier dans GitLab
    # Format: hostname/fichier.yml
    file_path = f"{hostname}/{fichier.value}"
    
    # Encoder le chemin pour l'URL (remplacer / par %2F)
    encoded_file_path = file_path.replace("/", "%2F")
    
    # Construire l'URL GitLab API
    gitlab_api_url = f"{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/repository/files/{encoded_file_path}/raw"
    
    # Paramètres de la requête GitLab
    params = {
        "ref": GITLAB_BRANCH
    }
    
    headers = {
        "PRIVATE-TOKEN": GITLAB_TOKEN
    }
    
    # Effectuer la requête vers GitLab
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                gitlab_api_url,
                params=params,
                headers=headers,
                timeout=30.0
            )
            
            if response.status_code == 404:
                raise HTTPException(
                    status_code=404,
                    detail=f"Fichier '{file_path}' non trouvé dans GitLab pour l'environnement {environnement}"
                )
            elif response.status_code == 401:
                raise HTTPException(
                    status_code=500,
                    detail="Erreur d'authentification avec GitLab"
                )
            elif response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Erreur GitLab: {response.text}"
                )
            
            # Retourner le contenu du fichier
            return {
                "environnement": environnement,
                "fichier": fichier,
                "hostname": hostname,
                "chef_complet": file_path,
                "contenu": response.text,
                "gitlab_url": gitlab_api_url
            }
            
        except httpx.TimeoutException:
            raise HTTPException(status_code=504, detail="Timeout GitLab")
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail=f"Erreur requête GitLab: {str(e)}")

@app.get("/fichier-git/raw")
async def get_file_raw(
    environnement: Environnement,
    fichier: Fichier
):
    """
    Retourne uniquement le contenu brut du fichier
    """
    hostname = ENV_HOSTNAME_MAPPING.get(environnement.value)
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": GITLAB_TOKEN}
    params = {"ref": GITLAB_BRANCH}
    
    async with httpx.AsyncClient() as client:
        response = await client.get(gitlab_api_url, params=params, headers=headers)
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Fichier non trouvé")
        
        return response.text

@app.get("/fichiers-disponibles")
async def list_available_files():
    """
    Liste tous les environnements et fichiers disponibles
    """
    return {
        "environnements": list(ENV_HOSTNAME_MAPPING.keys()),
        "fichiers": AVAILABLE_FILES,
        "mapping": ENV_HOSTNAME_MAPPING
    }
