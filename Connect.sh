#!/bin/bash
# ======================================================================
# 📦  connect - Gestionnaire de sessions SSH par application/environnement
# ======================================================================
#
# 📁  Fichiers de config : ~/.sessions/<application>.ini
#
# 📝  Format d'un fichier INI :
#     [environnement]
#     host=192.168.1.10
#     user=admin
#     port=2222    # optionnel, défaut = 22
#
# 🚀  Utilisation :
#     connect                    → Liste toutes les applications
#     connect <appli>            → Liste les environnements disponibles
#     connect <appli> help       → Affiche les détails (host/user/port)
#     connect <appli> <env>      → Connexion SSH
#
# 📌  Exemples :
#     connect appli1             → Affiche : prod, dev, recette
#     connect appli1 help        → Affiche : prod → admin@192.168.1.10:22
#     connect appli1 dev         → ssh -p 2222 admin@192.168.1.11
#
# ======================================================================

# Usage: connect <application> [environnement|help]

CONFIG_DIR="$HOME/.sessions"

# Fonction : lister les applications disponibles
list_apps() {
    echo "📦 Applications disponibles :"
    ls "$CONFIG_DIR"/*.ini 2>/dev/null | sed 's/.*\///' | sed 's/\.ini//' | sort
}

# Fonction : extraire une section INI
get_section() {
    local file="$1"
    local section="$2"
    awk -v s="[$section]" '
        $0 == s { capture=1; next }
        /^\[.*\]/ && capture { exit }
        capture && /^[[:space:]]*[^;#=]+=/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            key = $0; sub(/=.*/, "", key); gsub(/[[:space:]]+$/, "", key)
            value = $0; sub(/^[^=]*=[[:space:]]*/, "", value); gsub(/[[:space:]]+$/, "", value)
            print key "=" value
        }
    ' "$file"
}

# Fonction : afficher les environnements (simple)
list_envs() {
    local app="$1"
    local file="$CONFIG_DIR/$app.ini"
    echo "🌍 Environnements disponibles pour '$app' :"
    grep '^\[.*\]' "$file" | tr -d '[]' | sed 's/^/  /'
}

# Fonction : afficher les détails (help)
show_help() {
    local app="$1"
    local file="$CONFIG_DIR/$app.ini"
    echo "📖 Détails pour '$app' :"
    for env in $(grep '^\[.*\]' "$file" | tr -d '[]'); do
        local host=$(get_section "$file" "$env" | grep '^host=' | cut -d= -f2)
        local user=$(get_section "$file" "$env" | grep '^user=' | cut -d= -f2)
        local port=$(get_section "$file" "$env" | grep '^port=' | cut -d= -f2)
        port=${port:-22}
        echo "  $env → $user@$host:$port"
    done
}

# --- Début du script ---

# Vérifier que le dossier des configs existe
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ Dossier $CONFIG_DIR inexistant"
    exit 1
fi

# Cas : pas d'argument
if [ $# -eq 0 ]; then
    list_apps
    exit 0
fi

APP=$1
FILE="$CONFIG_DIR/$APP.ini"

# Vérifier que l'application existe
if [ ! -f "$FILE" ]; then
    echo "❌ Application '$APP' inconnue"
    list_apps
    exit 1
fi

# Cas : help
if [ "$2" = "help" ]; then
    show_help "$APP"
    exit 0
fi

# Cas : pas d'environnement
if [ -z "$2" ]; then
    list_envs "$APP"
    exit 0
fi

# Cas : connexion
ENV=$2
HOST=$(get_section "$FILE" "$ENV" | grep '^host=' | cut -d= -f2)
USER=$(get_section "$FILE" "$ENV" | grep '^user=' | cut -d= -f2)
PORT=$(get_section "$FILE" "$ENV" | grep '^port=' | cut -d= -f2)

if [ -z "$HOST" ] || [ -z "$USER" ]; then
    echo "❌ Environnement '$ENV' inconnu pour '$APP'"
    list_envs "$APP"
    exit 1
fi

# Connexion SSH
echo "🔌 Connexion à $APP ($ENV) : $USER@$HOST${PORT:+:$PORT}"
if [ -n "$PORT" ]; then
    ssh -p "$PORT" "$USER@$HOST"
else
    ssh "$USER@$HOST"
fi
