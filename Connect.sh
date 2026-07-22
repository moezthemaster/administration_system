#!/bin/bash
# Usage: connect appli1 dev

if [ $# -lt 2 ]; then
    echo "Usage: connect <application> <environnement>"
    echo ""
    echo "Applications disponibles :"
    ls ~/.sessions/*.ini 2>/dev/null | sed 's/.*\///' | sed 's/\.ini//'
    exit 1
fi

APP=$1
ENV=$2
FILE="$HOME/.sessions/$APP.ini"

if [ ! -f "$FILE" ]; then
    echo "❌ Application '$APP' inconnue"
    echo "Liste : $(ls ~/.sessions/*.ini | sed 's/.*\///' | sed 's/\.ini//' | tr '\n' ' ')"
    exit 1
fi

# Extraire les infos de la section [$ENV]
HOST=$(awk -F= -v s="[$ENV]" '/\[/ {section=$0} $0 ~ s {getline; if(/host/) print $2}' "$FILE" | tr -d ' ')
USER=$(awk -F= -v s="[$ENV]" '/\[/ {section=$0} $0 ~ s {getline; if(/user/) print $2}' "$FILE" | tr -d ' ')
PORT=$(awk -F= -v s="[$ENV]" '/\[/ {section=$0} $0 ~ s {getline; if(/port/) print $2}' "$FILE" | tr -d ' ')

if [ -z "$HOST" ] || [ -z "$USER" ]; then
    echo "❌ Environnement '$ENV' non trouvé dans $APP.ini"
    echo "Environnements disponibles :"
    grep '^\[.*\]' "$FILE" | tr -d '[]'
    exit 1
fi

# Connexion
echo "🔌 Connexion à $APP ($ENV) : $USER@$HOST${PORT:+:$PORT}"
if [ -n "$PORT" ]; then
    ssh -p "$PORT" "$USER@$HOST"
else
    ssh "$USER@$HOST"
fi
