from fastapi import FastAPI, HTTPException, Depends, Header
from typing import Optional
import httpx
from enum import Enum
import settings

app = FastAPI(title="GitLab File Viewer API")

class Environnement(str, Enum):
    DEV = "dev"
    HOMOL = "homol"
    PROD = "prod"

class Fichier(str, Enum):
    WILDFLY = "wildfly.yml"
    JBOSS = "jboss.yaml"

# Vérification du token
def verify_token(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Token manquant")
    
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Format invalide. Utilisez: Authorization: Bearer <token>")
    
    if token != settings.API_TOKEN:
        raise HTTPException(status_code=403, detail="Token invalide")
    
    return token

@app.get("/fichier-git")
async def get_file_from_git(
    environnement: Environnement,
    fichier: Fichier,
    token: str = Depends(verify_token)
):
    """Récupère un fichier depuis GitLab"""
    
    hostname = settings.ENV_HOSTNAME_MAPPING.get(environnement.value)
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{settings.GITLAB_URL}/api/v4/projects/{settings.PROJECT_ID}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": settings.GITLAB_TOKEN}
    params = {"ref": settings.GITLAB_BRANCH}
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(gitlab_api_url, params=params, headers=headers, timeout=30.0)
            
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail=f"Fichier '{file_path}' non trouvé")
            elif response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"Erreur GitLab: {response.text}")
            
            return {
                "environnement": environnement.value,
                "fichier": fichier.value,
                "hostname": hostname,
                "chemin": file_path,
                "contenu": response.text
            }
            
        except httpx.TimeoutException:
            raise HTTPException(status_code=504, detail="Timeout GitLab")

@app.get("/fichier-git/raw")
async def get_file_raw(
    environnement: Environnement,
    fichier: Fichier,
    token: str = Depends(verify_token)
):
    """Retourne le contenu brut du fichier"""
    
    hostname = settings.ENV_HOSTNAME_MAPPING.get(environnement.value)
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{settings.GITLAB_URL}/api/v4/projects/{settings.PROJECT_ID}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": settings.GITLAB_TOKEN}
    params = {"ref": settings.GITLAB_BRANCH}
    
    async with httpx.AsyncClient() as client:
        response = await client.get(gitlab_api_url, params=params, headers=headers)
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Fichier non trouvé")
        
        return response.text

@app.get("/fichiers-disponibles")
async def list_available_files(token: str = Depends(verify_token)):
    """Liste les environnements et fichiers disponibles"""
    return {
        "environnements": list(settings.ENV_HOSTNAME_MAPPING.keys()),
        "fichiers": settings.AVAILABLE_FILES,
        "mapping": settings.ENV_HOSTNAME_MAPPING
    }

@app.get("/health")
async def health_check():
    """Health check sans authentification"""
    return {"status": "ok"}
