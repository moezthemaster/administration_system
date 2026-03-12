#!/bin/bash

# Liste par défaut si aucune app n'est spécifiée
DEFAULT_APPS=("wildfly" "nginx" "postgres")
FORCE=false
ACTION=""
STATUS_APP=""

# ==============================
# Fonction de génération du rapport
# ==============================
status_report() {
    local apps=("$@")
    
    echo "===================================="
    echo "        APPLICATION STATUS"
    echo "===================================="
    echo "Report generated: $(date)"
    echo ""
    
    # En-tête
    printf "%-15s | %-10s | %-8s | %-20s | %-10s | %-10s\n" "APP" "STATUS" "PID" "START TIME" "USER" "PORTS"
    printf "%-15s-+-%-10s-+-%-8s-+-%-20s-+-%-10s-+-%-10s\n" "---------------" "----------" "--------" "--------------------" "----------" "----------"
    
    for app in "${apps[@]}"; do
        PID=$(pgrep -f $app | head -1)
        
        if [ -n "$PID" ]; then
            STATUS="RUNNING"
            USER=$(ps -p $PID -o user=)
            START_TIME=$(ps -p $PID -o lstart=)
            PORTS=$(ss -lntp 2>/dev/null | grep $PID | awk '{print $4}' | paste -sd "," -)
            [ -z "$PORTS" ] && PORTS="-"
        else
            STATUS="STOPPED"
            PID="-"
            USER="-"
            START_TIME="-"
            PORTS="-"
        fi
        
        printf "%-15s | %-10s | %-8s | %-20s | %-10s | %-10s\n" "$app" "$STATUS" "$PID" "$START_TIME" "$USER" "$PORTS"
    done
    
    echo ""
}

# ==============================
# Parsing des options
# ==============================
OPTS=$(getopt -o a:fs: -l action:,force,status:,help -- "$@")
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
            STATUS_APP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-a action] [-f] [-s app]"
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
        ;;
    stop)
        if [ "$FORCE" = true ]; then
            echo "Stop forcé"
        else
            echo "Stop normal"
        fi
        ;;
    status)
        if [ -n "$STATUS_APP" ]; then
            status_report "$STATUS_APP"
        else
            status_report "${DEFAULT_APPS[@]}"
        fi
        ;;
    *)
        echo "Action inconnue"
        ;;
esac
