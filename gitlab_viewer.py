
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import PlainTextResponse, Response
import httpx
from enum import Enum
import settings

app = FastAPI(title="GitLab File Viewer API")

# Configuration du security scheme
security = HTTPBearer()

# Définition des environnements disponibles
class Environnement(str, Enum):
    DEV = "dev"
    PROTO = "proto"
    HOMOL_PRIMAIRE = "homol_primaire"
    HOMOL_SECOURS = "homol_secours"
    PROD_PRIMAIRE = "prod_primaire"
    PROD_SECOURS = "prod_secours"

# Définition des fichiers disponibles
class Fichier(str, Enum):
    WILDFLY = "wildfly.yml"
    JBOSS = "jboss.yaml"

# Vérification du token
def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    if token != settings.API_TOKEN:
        raise HTTPException(status_code=403, detail="Token invalide")
    return token

@app.get("/fichier-git")
async def get_file_from_git(
    environnement: Environnement,
    fichier: Fichier,
    token: str = Depends(verify_token)
):
    """Récupère un fichier depuis GitLab avec ses métadonnées"""
    
    config = settings.ENV_CONFIG.get(environnement.value)
    if not config:
        raise HTTPException(status_code=400, detail=f"Environnement '{environnement.value}' non configuré")
    
    hostname = config["hostname"]
    project_id = config["project_id"]
    
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{settings.GITLAB_URL}/api/v4/projects/{project_id}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": settings.GITLAB_TOKEN}
    params = {"ref": settings.GITLAB_BRANCH}
    
    async with httpx.AsyncClient(verify=settings.GITLAB_VERIFY_SSL) as client:
        try:
            response = await client.get(gitlab_api_url, params=params, headers=headers, timeout=30.0)
            
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail=f"Fichier '{file_path}' non trouvé")
            elif response.status_code == 401:
                raise HTTPException(status_code=500, detail="Erreur d'authentification GitLab")
            elif response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"Erreur GitLab: {response.text}")
            
            return {
                "environnement": environnement.value,
                "fichier": fichier.value,
                "hostname": hostname,
                "project_id": project_id,
                "chemin": file_path,
                "contenu": response.text
            }
            
        except httpx.TimeoutException:
            raise HTTPException(status_code=504, detail="Timeout GitLab")
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail=f"Erreur requête GitLab: {str(e)}")

@app.get("/fichier-git/raw")
async def get_file_raw(
    environnement: Environnement,
    fichier: Fichier,
    token: str = Depends(verify_token),
    download: bool = False
):
    """Retourne le contenu brut du fichier YAML (ou le télécharge)"""
    
    config = settings.ENV_CONFIG.get(environnement.value)
    if not config:
        raise HTTPException(status_code=400, detail=f"Environnement '{environnement.value}' non configuré")
    
    hostname = config["hostname"]
    project_id = config["project_id"]
    
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{settings.GITLAB_URL}/api/v4/projects/{project_id}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": settings.GITLAB_TOKEN}
    params = {"ref": settings.GITLAB_BRANCH}
    
    async with httpx.AsyncClient(verify=settings.GITLAB_VERIFY_SSL) as client:
        try:
            response = await client.get(gitlab_api_url, params=params, headers=headers, timeout=30.0)
            
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail=f"Fichier '{file_path}' non trouvé")
            elif response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"Erreur GitLab: {response.text}")
            
            if download:
                # Force le téléchargement
                return Response(
                    content=response.text,
                    media_type="application/octet-stream",
                    headers={
                        "Content-Disposition": f"attachment; filename={environnement.value}_{fichier.value}"
                    }
                )
            else:
                # Affiche dans le navigateur/terminal
                return Response(
                    content=response.text,
                    media_type="text/plain"
                )
            
        except httpx.TimeoutException:
            raise HTTPException(status_code=504, detail="Timeout GitLab")
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail=f"Erreur requête GitLab: {str(e)}")

@app.get("/fichiers-disponibles")
async def list_available_files(token: str = Depends(verify_token)):
    """Liste les environnements et fichiers disponibles"""
    return {
        "environnements": [
            {
                "name": env,
                "hostname": config["hostname"],
                "project_id": config["project_id"]
            }
            for env, config in settings.ENV_CONFIG.items()
        ],
        "fichiers": settings.AVAILABLE_FILES
    }

@app.get("/health")
async def health_check():
    """Health check sans authentification"""
    return {"status": "ok"}
