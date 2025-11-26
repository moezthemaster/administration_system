
# Script PowerShell pour extraire les informations des fichiers Word SANS Microsoft Word
param(
    [string]$DirectoryPath = "."
)

Add-Type -AssemblyName System.IO.Packaging

function Get-WordFileInfo {
    param([string]$FilePath)
    
    try {
        # Ouvrir le fichier Word comme un ZIP (car .docx est un format ZIP)
        $package = [System.IO.Packaging.Package]::Open($FilePath, [System.IO.FileMode]::Open)
        $documentPart = $package.GetPart([System.IO.Packaging.PackUriHelper]::CreatePartUri("/word/document.xml"))
        
        $stream = $documentPart.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $xmlContent = $reader.ReadToEnd()
        $reader.Close()
        $package.Close()
        
        # Extraire le texte brut du XML
        $plainText = Extract-TextFromXml -XmlContent $xmlContent
        
        # Extraire les informations
        $description = Get-Description -Content $plainText
        $jiraNumber = Get-JiraNumber -Content $plainText
        
        # Obtenir la date de création du fichier
        $fileInfo = Get-Item $FilePath
        $dateCreation = $fileInfo.CreationTime
        
        return @{
            Fichier = [System.IO.Path]::GetFileName($FilePath)
            Description = $description
            NumeroJira = $jiraNumber
            DateCreation = $dateCreation
        }
    }
    catch {
        Write-Host "Erreur avec $FilePath : $_" -ForegroundColor Red
        return $null
    }
}

function Extract-TextFromXml {
    param([string]$XmlContent)
    
    # Extraire le texte entre les balises <w:t>
    $textMatches = [regex]::Matches($XmlContent, '<w:t[^>]*>([^<]*)</w:t>')
    $textBuilder = New-Object System.Text.StringBuilder
    
    foreach ($match in $textMatches) {
        if ($match.Groups[1].Value -ne $null -and $match.Groups[1].Value.Trim() -ne "") {
            [void]$textBuilder.Append($match.Groups[1].Value + " ")
        }
    }
    
    return $textBuilder.ToString().Trim()
}

function Get-Description {
    param([string]$Content)
    
    # Recherche "description" et prend le texte qui suit (jusqu'au prochain saut de ligne ou fin)
    if ($Content -match "(?i)description[:\s]*([^\r\n]*)") {
        return $matches[1].Trim()
    }
    return "Non trouvée"
}

function Get-JiraNumber {
    param([string]$Content)
    
    # Pattern pour les numéros Jira (ex: ABC-123, PROJ-456, PROJ-1234)
    if ($Content -match "[A-Z]{2,}-\d+") {
        return $matches[0]
    }
    return "Non trouvé"
}

# Traitement principal
Write-Host "Analyse des fichiers Word" -ForegroundColor Cyan
Write-Host "Repertoire: $((Get-Item $DirectoryPath).FullName)" -ForegroundColor Yellow

$wordFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.docx" | Where-Object { !$_.Name.StartsWith("~") }

if ($wordFiles.Count -eq 0) {
    Write-Host "Aucun fichier Word (.docx) trouve dans le repertoire." -ForegroundColor Red
    exit
}

Write-Host "Fichiers trouves: $($wordFiles.Count)" -ForegroundColor Green
Write-Host ""

# Traiter chaque fichier
foreach ($file in $wordFiles) {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "FICHIER: $($file.Name)" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $fileInfo = Get-WordFileInfo -FilePath $file.FullName
    
    if ($fileInfo) {
        Write-Host "DATE DE CREATION: $($fileInfo.DateCreation.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Yellow
        Write-Host "DESCRIPTION: $($fileInfo.Description)" -ForegroundColor White
        Write-Host "NUMERO JIRA: $($fileInfo.NumeroJira)" -ForegroundColor White
    }
    
    Write-Host ""
}

Write-Host "Analyse terminee !" -ForegroundColor Green
