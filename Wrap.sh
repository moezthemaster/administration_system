#!/usr/bin/env bash

# Le premier argument est le script cible (python ou R)
TARGET="$1"
shift  # On enlève le nom du script pour garder uniquement les paramètres

# Détermine si c'est un script Python ou R
ext="${TARGET##*.}"

if [ "$ext" = "py" ]; then
    python3 "$TARGET" "$@"
elif [ "$ext" = "R" ] || [ "$ext" = "r" ]; then
    Rscript "$TARGET" "$@"
else
    echo "Extension non supportée: $ext"
    exit 1
fi
