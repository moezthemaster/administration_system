# 1. Sur une machine avec internet, télécharger
wget https://update.code.visualstudio.com/latest/server-linux-x64/stable -O vscode-server-latest.tar.gz

# 2. Transférer sur la VM
scp vscode-server-latest.tar.gz monuser@192.168.1.100:~/

# 3. Sur la VM, créer la structure
ssh monuser@192.168.1.100
mkdir -p ~/.vscode-server/bin
cd ~/.vscode-server/bin

# 4. Extraire avec le bon commit (le commit est dans le nom du dossier extrait)
tar -xzf ~/vscode-server-latest.tar.gz
# Notez le nom du dossier créé
mv vscode-server-* ${VOTRE_COMMIT_ID}
touch ${VOTRE_COMMIT_ID}/0

{
    "remote.SSH.allowLocalServerDownload": true,
    "remote.SSH.localServerDownload": "always",
    "remote.downloadExtensionsLocally": true,
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.useLocalServer": false
}
