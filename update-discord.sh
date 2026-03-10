#!/bin/bash
# =============================================================================
# Discord Auto-Updater for Linux (Arch)
# Checks for a new version before downloading
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
INSTALL_DIR="/opt/Discord"
BINARY="$INSTALL_DIR/Discord"
DOWNLOAD_URL="https://discord.com/api/download/stable?platform=linux&format=tar.gz"
TMP_FILE="/tmp/discord-update-$$.tar.gz"
VERSION_FILE="$INSTALL_DIR/.installed_version"
LOG_FILE="/var/log/discord-update.log"
# -----------------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT

# Ensure log file is writable
sudo touch "$LOG_FILE" 2>/dev/null || true
sudo chmod 666 "$LOG_FILE" 2>/dev/null || true

log "--- Discord update check started ---"

# --- Get installed version ---------------------------------------------------
INSTALLED_VERSION="none"
if [[ -f "$BINARY" ]]; then
    # Try reading from our cached version file first
    if [[ -f "$VERSION_FILE" ]]; then
        INSTALLED_VERSION=$(cat "$VERSION_FILE")
    else
        # TODO: Using the --version flag starts discord and therefore the script wont continue 
        # Fall back to parsing the binary's --version output
        INSTALLED_VERSION=$("$BINARY" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    fi
fi
log "Installed version : $INSTALLED_VERSION"

# --- Get latest version from Discord API -------------------------------------
log "Checking latest version from Discord API..."
API_RESPONSE=$(curl -sI "$DOWNLOAD_URL" 2>/dev/null || true)

# The redirect URL contains the version number, e.g. discord-0.0.72.tar.gz
LATEST_VERSION=$(echo "$API_RESPONSE" \
    | grep -i "location:" \
    | grep -oP '\d+\.\d+\.\d+' \
    | head -1 || true)

if [[ -z "$LATEST_VERSION" ]]; then
    # Fallback: resolve the redirect and parse the final filename
    FINAL_URL=$(curl -sLI "$DOWNLOAD_URL" -o /dev/null -w '%{url_effective}' 2>/dev/null || true)
    LATEST_VERSION=$(echo "$FINAL_URL" | grep -oP '\d+\.\d+\.\d+' | head -1 || true)
fi

if [[ -z "$LATEST_VERSION" ]]; then
    log "ERROR: Could not determine latest version from API. Aborting."
    exit 1
fi
log "Latest version    : $LATEST_VERSION"

# --- Compare versions --------------------------------------------------------
if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
    log "Already up to date ($INSTALLED_VERSION). Nothing to do."
    log "--- Done ---"
    exit 0
fi

log "Update available: $INSTALLED_VERSION -> $LATEST_VERSION. Starting download..."

# --- Download ----------------------------------------------------------------
curl -L --progress-bar "$DOWNLOAD_URL" -o "$TMP_FILE"
log "Download complete: $TMP_FILE"

# --- Install -----------------------------------------------------------------
log "Installing to $INSTALL_DIR ..."
sudo tar xzf "$TMP_FILE" -C /opt

# Cache the new version so future checks are instant
echo "$LATEST_VERSION" | sudo tee "$VERSION_FILE" > /dev/null

log "Successfully updated Discord to $LATEST_VERSION"

# Send toast message
notify-send Discord Updated "Successfully updated Discord to $LATEST_VERSION"

log "--- Done ---"

