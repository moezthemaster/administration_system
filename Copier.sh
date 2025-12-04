#!/bin/bash

CONFIG_FILE="config.conf"

# Lire chaque ligne non vide et non commentée
while IFS='|' read -r SRC DEST FILE_MODE _; do
    [[ -z "$SRC" || "$SRC" =~ ^# ]] && continue

    echo "Copie de $SRC vers $DEST …"

    # Copier récursivement les fichiers seulement (les dossiers existent déjà)
    cp -r "$SRC/"* "$DEST/"

    # Appliquer les droits uniquement sur les fichiers
    find "$DEST" -type f -exec chmod "$FILE_MODE" {} \;

    echo "Copie terminée pour $DEST"

done < "$CONFIG_FILE"


#################
#!/bin/bash

CONFIG_FILE="config.conf"

# Lire chaque ligne non vide et non commentée
while IFS='|' read -r SRC DEST FILE_MODE; do
    [[ -z "$SRC" || "$SRC" =~ ^# ]] && continue

    echo "Traitement de $SRC -> $DEST …"

    # Créer le dossier destination si nécessaire
    mkdir -p "$DEST"

    # Parcourir tous les fichiers dans SRC
    find "$SRC" -type f | while read -r FILE; do
        # Chemin relatif par rapport à SRC
        REL_PATH="${FILE#$SRC/}"
        DEST_FILE="$DEST/$REL_PATH"

        # Créer le dossier parent si nécessaire
        mkdir -p "$(dirname "$DEST_FILE")"

        # Copier seulement si le fichier n'existe pas ou a été modifié
        if [[ ! -f "$DEST_FILE" || "$FILE" -nt "$DEST_FILE" ]]; then
            cp "$FILE" "$DEST_FILE"
            chmod "$FILE_MODE" "$DEST_FILE"
            echo "Copié : $REL_PATH"
        fi
    done

    echo "Traitement terminé pour $DEST"

done < "$CONFIG_FILE"
