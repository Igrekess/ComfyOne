#!/bin/bash

# Détection si on est dans un terminal
if [ ! -t 1 ]; then
    # Obtenir les dimensions de l'écran
    screen_size=$(osascript -e 'tell application "Finder"
        set screenSize to bounds of window of desktop
        return item 3 of screenSize & "," & item 4 of screenSize
    end tell')
    
    screen_width=$(echo $screen_size | cut -d',' -f1)
    screen_height=$(echo $screen_size | cut -d',' -f2)
    
    # Calculer les dimensions
    window_width=$((screen_width / 3))
    window_height=$((screen_height * 2 / 3))
    
    # Position X (à droite de l'écran)
    pos_x=$((screen_width - window_width))
    # Position Y (en haut)
    pos_y=0
    # Afficher un message coloré
echo -e "${BOLD}${GREEN}Lancement de la génération...${NC}"
    
    osascript <<EOF
        tell application "Terminal"
            activate
            
            -- Créer une nouvelle fenêtre avec paramètres personnalisés
            set newWindow to do script ""
            
            -- Appliquer les réglages visuels
            tell window 1
                set background color to {0, 0, 0}  -- Noir
                set normal text color to {32768, 0, 0}  -- rouge
                set cursor color to {65535, 65535, 65535}  -- Blanc
                set font name to "Menlo"
                set font size to 13
                set bounds to {$pos_x, $pos_y, $((pos_x + window_width)), $((pos_y + window_height))}
            end tell
            
            -- Exécuter la commande
            do script "cd '$SCRIPT_DIR' && '$0' '$@' --in-terminal" in window 1
        end tell
EOF
    exit 0
fi

# Si --in-terminal est présent, on est dans le nouveau terminal
if [[ ! "$*" =~ "--in-terminal" ]]; then
    exit 0
fi

# Activer le mode debug
set -x

# Créer un fichier de log unique pour cette exécution
LOG_FILE="/tmp/comfy_generate_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Log de démarrage
#echo "=== Démarrage de generate.sh $(date) ==="

# Chemin de l'environnement virtuel basé sur le répertoire du script actuel
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#echo "SCRIPT_DIR: $SCRIPT_DIR"

VENV_DIR="$SCRIPT_DIR/ComfyONE_env"
#echo "VENV_DIR: $VENV_DIR"

# Vérifier si l'environnement virtuel existe
if [ ! -d "$VENV_DIR" ]; then
    echo "Erreur: Environnement virtuel non trouvé: $VENV_DIR"
    exit 1
fi

# Activer l'environnement virtuel
source "$VENV_DIR/bin/activate"
#echo "Python path après activation: $(which python3)"

# Chemin vers le fichier temporaire contenant les arguments
ARGS_FILE="/tmp/comfyOne_args.txt"

# Vérifier si le fichier d'arguments existe
if [ -f "$ARGS_FILE" ]; then
    echo "Fichier d'arguments trouvé"
    echo "Contenu du fichier:"
    cat "$ARGS_FILE"
    
    # Lire les variables depuis le fichier avec évaluation des guillemets
    eval "set -- $(< "$ARGS_FILE")"
    
    # Log des arguments
    echo "Nombre d'arguments: $#"
    
    # Vérifier si main.py existe
    if [ ! -f "$SCRIPT_DIR/ComfyOne.py" ]; then
        echo "Erreur: ComfyOne.py non trouvé: $SCRIPT_DIR/ComfyOne.py"
        exit 1
    fi
    
    # Exécuter main.py avec redirection complète des sorties
    echo "Lancement de ComfyOne.py..."
    python3 "$SCRIPT_DIR/ComfyOne.py" "$@" 2>&1 | tee -a "$LOG_FILE"
    
    # Capturer le code de retour
    EXIT_CODE=${PIPESTATUS[0]}
    echo "Code de retour de ComfyOne.py: $EXIT_CODE"
    
    # Supprimer le fichier d'arguments après utilisation
    #rm "$ARGS_FILE"
    echo "Fichier d'arguments supprimé"
else
    echo "Erreur: Le fichier des arguments est introuvable: $ARGS_FILE"
    exit 1
fi

#echo "=== Fin de generate.sh $(date) ==="