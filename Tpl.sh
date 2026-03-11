#!/bin/bash

# ==============================
# Variables
# ==============================

ACTION=""
FORCE=false

# ==============================
# Fonction help
# ==============================

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --action {start|stop}   Action à exécuter"
    echo "      --status                Affiche le statut"
    echo "      --force                 Force l'arrêt"
    echo "  -h, --help                  Affiche l'aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -a start"
    echo "  $0 --action stop --force"
    echo "  $0 --status"
    exit 1
}

# ==============================
# Parsing des arguments
# ==============================

OPTS=$(getopt -o a:h -l action:,force,status,help -- "$@")

if [ $? != 0 ]; then
    usage
fi

eval set -- "$OPTS"

while true; do
    case "$1" in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            ;;
    esac
done

# ==============================
# Fonctions actions
# ==============================

start_app() {
    echo "Démarrage de l'application..."
}

stop_app() {
    if [ "$FORCE" = true ]; then
        echo "Arrêt forcé de l'application..."
    else
        echo "Arrêt normal de l'application..."
    fi
}

status_app() {
    echo "Statut de l'application..."
}

# ==============================
# Exécution
# ==============================

case "$ACTION" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    status)
        status_app
        ;;
    *)
        echo "Action invalide"
        usage
        ;;
esac
