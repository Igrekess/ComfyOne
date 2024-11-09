#!/bin/bash

# Vérifie si Python 3.10 est installé
if ! command -v python3.10 &> /dev/null
then
    echo "Python 3.10 n'est pas installé. Veuillez l'installer pour continuer."
    exit 1
fi

# Utilise le répertoire actuel comme répertoire d'installation
SCRIPT_DIR="$(pwd)"
echo "Installation dans le répertoire : $SCRIPT_DIR"

# Chemin pour l'environnement virtuel
VENV_DIR="$SCRIPT_DIR/comfyONE_env"
mkdir -p "$VENV_DIR"

# Crée l'environnement virtuel avec Python 3.10
python3.10 -m venv "$VENV_DIR"

# Active l'environnement virtuel
source "$VENV_DIR/bin/activate"

# Installe les packages nécessaires
pip install websocket-client requests Pillow

# Confirmation de l'installation de l'environnement virtuel
echo "Environnement virtuel Python 3.10 créé et activé dans le dossier : $VENV_DIR"
echo "Les packages websocket-client, requests, et Pillow ont été installés."

# Chemin pour le fichier .plist
PLIST_PATH=~/Library/LaunchAgents/com.yse.comfyONE.plist

# Créer le fichier .plist avec les chemins dynamiques
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.yse.comfyONE</string>

    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>$SCRIPT_DIR/generate.sh</string>
    </array>

    <key>KeepAlive</key>
    <false/>

    <key>RunAtLoad</key>
    <false/>

    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/log/generate_stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/log/generate_stderr.log</string>

    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>DISPLAY</key>
        <string>:0</string>
        <key>TERM</key>
        <string>xterm-256color</string>
    </dict>

    <key>ProcessType</key>
    <string>Interactive</string>

    <key>AbandonProcessGroup</key>
    <true/>
  </dict>
</plist>
EOF


# Vérifie si le répertoire des logs existe, sinon le crée
mkdir -p "$SCRIPT_DIR/log"

# Charge le fichier .plist avec launchctl
launchctl load "$PLIST_PATH"

echo "Installation terminée. Le fichier .plist a été créé et chargé avec launchctl."
echo "Le script Python s'exécutera en arrière-plan via launchctl."
