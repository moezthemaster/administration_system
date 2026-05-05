from fastapi.responses import PlainTextResponse, Response

@app.get("/fichier-git/raw")
async def get_file_raw(
    environnement: Environnement,
    fichier: Fichier,
    token: str = Depends(verify_token),
    download: bool = False  # ← Ajoutez ce paramètre
):
    """Retourne le contenu brut du fichier YAML"""
    
    hostname = ENV_HOSTNAME_MAPPING.get(environnement.value)
    file_path = f"{hostname}/{fichier.value}"
    encoded_file_path = file_path.replace("/", "%2F")
    
    gitlab_api_url = f"{settings.GITLAB_URL}/api/v4/projects/{settings.PROJECT_ID}/repository/files/{encoded_file_path}/raw"
    
    headers = {"PRIVATE-TOKEN": settings.GITLAB_TOKEN}
    params = {"ref": settings.GITLAB_BRANCH}
    
    async with httpx.AsyncClient(verify=False) as client:
        response = await client.get(gitlab_api_url, params=params, headers=headers)
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Fichier non trouvé")
        
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
            # Affiche dans le navigateur
            return Response(
                content=response.text,
                media_type="text/plain"
            )
