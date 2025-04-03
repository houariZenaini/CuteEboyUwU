#!/bin/bash

# === VARIABLES toute cute ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")  # les logs
LOG_DIR="./logs"                     # dossier des logs
LOG_FILE="$LOG_DIR/postinstall_$TIMESTAMP.log"  # Fencore des log je crois
CONFIG_DIR="./config"                 # dossier config ?
PACKAGE_LIST="./lists/packages.txt"    # Liste des paquets à installer
USERNAME=$(logname)                    # le nom d'user
USER_HOME="/home/$USERNAME"            # le répertoire home de l'utilisateur

# === FONCTIONS ===


log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" # j'ai pas compris
}

# ca check si tout et la sinon il l'install
check_and_install() {
  local pkg=$1
  if dpkg -s "$pkg" &>/dev/null; then
    log "$pkg est déjà installé."
  else
    log "Installation de $pkg..."
    apt install -y "$pkg" &>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
      log "$pkg installé avec succès."
    else
      log "Échec de l'installation de $pkg."
    fi
  fi
}

# question oui/non
ask_yes_no() {
  read -p "$1 [y/N]: " answer
  case "$answer" in
    [Yy]* ) return 0 ;;  
    * ) return 1 ;;      
  esac
}

# === INITIALISATION ===
mkdir -p "$LOG_DIR"   # Création du répertoire des logs 
touch "$LOG_FILE"     # fichier de log
log "Début du script post-installation. Utilisateur connecté : $USERNAME"

# si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  log "Ce script doit être exécuté en tant que root."
  exit 1
fi

# === 1. MISE À JOUR DU SYSTÈME ===
log "Mise à jour des paquets système..."
apt update && apt upgrade -y &>>"$LOG_FILE"

# === 2. INSTALLATION DES PAQUETS ===
if [ -f "$PACKAGE_LIST" ]; then
  log "Lecture de la liste des paquets depuis $PACKAGE_LIST"
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue  
    check_and_install "$pkg"
  done < "$PACKAGE_LIST"
else
  log "Fichier de liste des paquets non trouvé : $PACKAGE_LIST. Installation ignorée."
fi

# === 3. MISE À JOUR DU MOTD (Message du jour) ===
if [ -f "$CONFIG_DIR/motd.txt" ]; then
  cp "$CONFIG_DIR/motd.txt" /etc/motd
  log "MOTD mis à jour."
else
  log "Fichier motd.txt non trouvé."
fi

# === 4. PERSONNALISATION DU .bashrc ===
if [ -f "$CONFIG_DIR/bashrc.append" ]; then
  cat "$CONFIG_DIR/bashrc.append" >> "$USER_HOME/.bashrc"
  chown "$USERNAME:$USERNAME" "$USER_HOME/.bashrc"
  log ".bashrc personnalisé."
else
  log "Fichier bashrc.append non trouvé."
fi

# === 5. PERSONNALISATION DU .nanorc ===
if [ -f "$CONFIG_DIR/nanorc.append" ]; then
  cat "$CONFIG_DIR/nanorc.append" >> "$USER_HOME/.nanorc"
  chown "$USERNAME:$USERNAME" "$USER_HOME/.nanorc"
  log ".nanorc personnalisé."
else
  log "Fichier nanorc.append non trouvé."
fi

# === 6. AJOUT D'UNE CLÉ SSH PUBLIQUE ===
if ask_yes_no "Voulez-vous ajouter une clé SSH publique ?"; then
  read -p "Collez votre clé SSH publique : " ssh_key
  mkdir -p "$USER_HOME/.ssh"
  echo "$ssh_key" >> "$USER_HOME/.ssh/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
  chmod 700 "$USER_HOME/.ssh"
  chmod 600 "$USER_HOME/.ssh/authorized_keys"
  log "Clé SSH publique ajoutée."
fi

# === 7. CONFIGURATION DE SSH : AUTHENTIFICATION PAR CLÉ UNIQUEMENT ===
if [ -f /etc/ssh/sshd_config ]; then
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart ssh
  log "SSH configuré pour accepter uniquement l'authentification par clé."
else
  log "Fichier sshd_config introuvable."
fi

log "Script post-installation terminé."

exit 0
 
 # pour le reste du code pas besoin de le commenter 