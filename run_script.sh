#!/bin/bash

# Wrapper minimaliste CORRECT avec $@

SCRIPT=""
TIMEOUT=""
PYTHON_CMD=""

# ----------------------------------------------------------------------------
# FONCTIONS
# ----------------------------------------------------------------------------

log() {
    echo "[$(date +'%H:%M:%S')] $1"
}

get_interpreter() {
    local script="$1"
    local ext="${script##*.}"
    
    case "$ext" in
        py|python|py3)
            if [ -n "$PYTHON_CMD" ]; then
                echo "$PYTHON_CMD"
            else
                command -v python3 2>/dev/null || command -v python || {
                    log "ERROR: Python non trouvé"
                    return 1
                }
            fi
            ;;
        r|R)
            command -v Rscript || {
                log "ERROR: Rscript non trouvé"
                return 1
            }
            ;;
        *)
            log "ERROR: Extension .$ext non supportée"
            return 1
            ;;
    esac
}

run_with_timeout() {
    local timeout="$1"
    local interpreter="$2"
    local script="$3"
    shift 3  # Retire timeout, interpreter, script des arguments
    
    log "Exécution avec timeout de ${timeout}s"
    
    # CORRECT: Utiliser "$@" pour passer TOUS les arguments restants
    "$interpreter" "$script" "$@" &
    local pid=$!
    
    # Attendre avec timeout
    if wait "$pid" 2>/dev/null; then
        return $?
    else
        log "Timeout dépassé - arrêt"
        kill -TERM "$pid" 2>/dev/null
        return 124
    fi
}

main() {
    # Parse arguments du wrapper
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "Usage: $0 [options] script.[py|r] [args...]"
                echo "  -t, --timeout N    Timeout en secondes"
                echo "  --python CMD       Interpréteur Python personnalisé"
                exit 0
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --python)
                PYTHON_CMD="$2"
                shift 2
                ;;
            *)
                # Premier argument non-optionnel = script
                SCRIPT="$1"
                shift  # Passe au script
                break  # TOUT le reste va dans $@
                ;;
        esac
    done
    
    # Validation
    [ -z "$SCRIPT" ] && { log "ERROR: Script manquant"; exit 1; }
    [ ! -f "$SCRIPT" ] && { log "ERROR: Script non trouvé: $SCRIPT"; exit 1; }
    
    # Interpréteur
    local interpreter
    interpreter=$(get_interpreter "$SCRIPT") || exit $?
    
    log "Lancement: $interpreter $SCRIPT"
    [ -n "$TIMEOUT" ] && log "Timeout: ${TIMEOUT}s"
    
    # Exécution CORRECTE avec "$@"
    if [ -n "$TIMEOUT" ]; then
        run_with_timeout "$TIMEOUT" "$interpreter" "$SCRIPT" "$@"
    else
        "$interpreter" "$SCRIPT" "$@"
    fi
    
    exit $?
}

main "$@"
