#!/bin/bash

SERVICES=("nginx" "wildfly" "postgres")

ACTION=""
TARGET=""

# ==============================
# Fonctions
# ==============================

start_service() {
    local svc=$1
    echo "Démarrage de $svc"
}

stop_service() {
    local svc=$1
    echo "Arrêt de $svc"
}

status_service() {
    local svc=$1

    PID=$(pgrep -f "$svc" | head -1)

    if [ -n "$PID" ]; then
        echo "$svc : RUNNING (PID=$PID)"
    else
        echo "$svc : STOPPED"
    fi
}

run_on_services() {

    local list=()

    if [ -n "$TARGET" ]; then
        list=("$TARGET")
    else
        list=("${SERVICES[@]}")
    fi

    for svc in "${list[@]}"
    do
        case "$ACTION" in
            start)
                start_service "$svc"
                ;;
            stop)
                stop_service "$svc"
                ;;
            status)
                status_service "$svc"
                ;;
        esac
    done
}

# ==============================
# Parsing arguments
# ==============================

case "$1" in
    --start)
        ACTION="start"
        TARGET="$2"
        ;;
    --stop)
        ACTION="stop"
        TARGET="$2"
        ;;
    --status)
        ACTION="status"
        TARGET="$2"
        ;;
    *)
        echo "Usage:"
        echo "$0 --start [service]"
        echo "$0 --stop [service]"
        echo "$0 --status [service]"
        exit 1
        ;;
esac

run_on_services
