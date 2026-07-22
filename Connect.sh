#!/bin/bash
# Usage: connect <application> <environnement>

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
    exit 1
fi

# --- Extraction propre de la section [ENV] ---
# On utilise awk : on se met en mode "capture" quand on trouve la section,
# on stocke les clés, et on s'arrête à la section suivante ou à la fin.
parse_ini_section() {
    awk -v section="[$ENV]" '
        $0 == section { capture=1; next }
        /^\[.*\]/ && capture { exit }
        capture && /^[[:space:]]*[^;#=]+=/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            key = $1; sub(/=.*/, "", key)
            value = $0; sub(/^[^=]*=[[:space:]]*/, "", value)
            gsub(/[[:space:]]+$/, "", value)
            print key "=" value
        }
    ' "$FILE"
}

# Récupérer les valeurs
HOST=$(parse_ini_section | grep '^host=' | cut -d= -f2)
USER=$(parse_ini_section | grep '^user=' | cut -d= -f2)
PORT=$(parse_ini_section | grep '^port=' | cut -d= -f2)

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
