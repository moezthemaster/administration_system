#!/bin/bash

# Liste des applications à vérifier
APPS=("wildfly" "nginx" "postgres")
ACTION=""
FORCE=false

# ==============================
# Fonction de génération du rapport
# ==============================
status_report() {
    echo "===================================="
    echo "        APPLICATION STATUS"
    echo "===================================="
    echo "Report generated: $(date)"
    echo ""
    
    # En-tête du tableau
    printf "%-15s | %-10s | %-8s\n" "APP" "STATUS" "PID"
    printf "%-15s-+-%-10s-+-%-8s\n" "---------------" "----------" "--------"
    
    # Boucle sur les applications
    for app in "${APPS[@]}"; do
        PID=$(pgrep -f $app | head -1)
        
        if [ -n "$PID" ]; then
            STATUS="RUNNING"
        else
            STATUS="STOPPED"
            PID="-"
        fi
        
        printf "%-15s | %-10s | %-8s\n" "$app" "$STATUS" "$PID"
    done
    
    echo ""
}

# ==============================
# Parsing des options
# ==============================
OPTS=$(getopt -o a:fs -l action:,force,status,help -- "$@")
if [ $? != 0 ]; then
    echo "Erreur dans les arguments"
    exit 1
fi
eval set -- "$OPTS"

while true; do
    case "$1" in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -s|--status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-a action] [-f] [-s]"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# ==============================
# Exécution
# ==============================
case "$ACTION" in
    start)
        echo "Start command"
        # ici ton code de démarrage
        ;;
    stop)
        if [ "$FORCE" = true ]; then
            echo "Stop forcé"
        else
            echo "Stop normal"
        fi
        # ici ton code d'arrêt
        ;;
    status)
        status_report
        ;;
    *)
        echo "Action inconnue"
        ;;
esac
