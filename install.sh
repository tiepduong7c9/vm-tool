#!/bin/bash
# VM Tool - One-line installer
# Install: curl -sL https://raw.githubusercontent.com/yourusername/t-vm-utils/main/install.sh | bash
# Uninstall: curl -sL https://raw.githubusercontent.com/yourusername/t-vm-utils/main/install.sh | bash -s -- uninstall

set -e

SCRIPT_NAME="vm-tool"
WRAPPER_NAME="vm-tool-wrapper"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
SUDOERS_FILE="/etc/sudoers.d/vm-tool-chrony"
CURRENT_USER=$(whoami)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Uninstall function
uninstall() {
    echo -e "${BLUE}[uninstall] Uninstalling vm-tool...${NC}"

    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        echo -e "${BLUE}[uninstall] Removing $INSTALL_DIR/$SCRIPT_NAME${NC}"
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    fi

    if [[ -f "$INSTALL_DIR/$WRAPPER_NAME" ]]; then
        echo -e "${BLUE}[uninstall] Removing wrapper script${NC}"
        rm -f "$INSTALL_DIR/$WRAPPER_NAME"
    fi

    if [[ -f "$DESKTOP_DIR/vm-tool.desktop" ]]; then
        echo -e "${BLUE}[uninstall] Removing desktop entry...${NC}"
        rm -f "$DESKTOP_DIR/vm-tool.desktop"
    fi

    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

    if [[ -f "$SUDOERS_FILE" ]]; then
        echo -e "${BLUE}[uninstall] Removing sudoers entry...${NC}"
        sudo rm -f "$SUDOERS_FILE"
    fi

    echo -e "${GREEN}[uninstall] Uninstallation complete!${NC}"
    exit 0
}

# Check for uninstall flag
if [[ "$1" == "uninstall" ]]; then
    uninstall
fi

# Install function
echo -e "${BLUE}[install] Installing vm-tool...${NC}"

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$DESKTOP_DIR"

# Write the main vm-tool script
cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'SCRIPT_EOF'
#!/bin/bash

# Auto-scale GNOME monitors based on resolution
# > 2500px width => 200%
# <= 2500px width => 100%
# Also syncs system time by restarting chrony

echo "[auto-scale] Scanning monitors..."

OUTPUT=$(gdctl show --modes)

declare -a MONITORS
declare -a SCALES
declare -a LOGICAL_WIDTHS

while IFS= read -r line; do
    if [[ "$line" =~ "Monitor" ]] && [[ "$line" =~ "MetaVendor" ]]; then
        MON=$(echo "$line" | grep -oP 'Monitor \K[\w-]+(?= \()')
        if [[ -n "$MON" ]]; then
            MONITORS+=("$MON")
        fi
    fi
done <<< "$OUTPUT"

while IFS= read -r line; do
    if [[ "$line" =~ [0-9]+x[0-9]+@ ]]; then
        WIDTH=$(echo "$line" | grep -oP '[0-9]+(?=x[0-9]+@)')
        if [[ -n "$WIDTH" ]]; then
            if (( WIDTH >= 2500 )); then
                SCALE=2
            else
                SCALE=1
            fi
            LOGICAL_WIDTH=$(( WIDTH / SCALE ))
            SCALES+=("$SCALE")
            LOGICAL_WIDTHS+=("$LOGICAL_WIDTH")
            echo "[auto-scale] Detected resolution: ${WIDTH}px, scale ${SCALE}x"
        fi
    fi
done <<< "$OUTPUT"

MONITOR_COUNT=${#MONITORS[@]}
echo "[auto-scale] Found $MONITOR_COUNT monitor(s)"

if [[ $MONITOR_COUNT -gt 0 ]]; then
    echo "[auto-scale] Applying layout..."
    POS_X=0
    FULL_CMD=""

    for ((i=0; i<MONITOR_COUNT; i++)); do
        MON="${MONITORS[$i]}"
        SCALE="${SCALES[$i]}"
        L_WIDTH="${LOGICAL_WIDTHS[$i]}"
        PRIMARY_FLAG=""
        if [[ $i -eq 0 ]]; then
            PRIMARY_FLAG="--primary"
        fi
        FULL_CMD+=" --logical-monitor --x $POS_X --y 0 --scale $SCALE $PRIMARY_FLAG --monitor $MON"
        POS_X=$(( POS_X + L_WIDTH ))
        echo "[auto-scale]   $MON: x=$POS_X, scale=$SCALE"
    done

    gdctl set $FULL_CMD
    echo "[auto-scale] Layout applied successfully"
else
    echo "[auto-scale] No monitors detected."
fi

echo ""
echo "[time-sync] Restarting chrony..."

if sudo -n systemctl restart chrony 2>/dev/null; then
    echo "[time-sync] Time sync completed"
else
    echo "[time-sync] Warning: systemctl restart chrony failed (needs sudo password or setup)"
    echo "[time-sync] Run installer to setup passwordless sudo: ./install.sh"
fi
SCRIPT_EOF

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Create wrapper script
cat > "$INSTALL_DIR/$WRAPPER_NAME" << 'WRAPPER_EOF'
#!/bin/bash
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u "$CURRENT_USER")
export DISPLAY=":0"
export XAUTHORITY="/run/user/$CURRENT_UID/gdm/Xauthority"
if [[ ! -f "$XAUTHORITY" ]]; then
    export XAUTHORITY="$HOME/.Xauthority"
fi
exec "$HOME/.local/bin/vm-tool"
WRAPPER_EOF

chmod +x "$INSTALL_DIR/$WRAPPER_NAME"

# Create desktop entry
cat > "$DESKTOP_DIR/vm-tool.desktop" << EOF
[Desktop Entry]
Type=Application
Name=VM Tool
Comment=Auto-scale monitors and sync time for VMs
Exec=$INSTALL_DIR/$WRAPPER_NAME
Icon=display
Terminal=true
Categories=Settings;System;HardwareSettings;
Keywords=monitor;display;scale;resolution;time;sync;vm;
EOF

chmod +x "$DESKTOP_DIR/vm-tool.desktop"

# Setup sudoers
echo -e "${BLUE}[install] Configuring passwordless chrony access...${NC}"

if [[ -f "$SUDOERS_FILE" ]]; then
    echo -e "${YELLOW}[install] Removing old sudoers file...${NC}"
    sudo rm -f "$SUDOERS_FILE"
fi

TEMP_SUDOERS=$(mktemp)
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart chrony" > "$TEMP_SUDOERS"

if sudo visudo -c -f "$TEMP_SUDOERS" >/dev/null 2>&1; then
    sudo install -m 0440 "$TEMP_SUDOERS" "$SUDOERS_FILE"
    rm -f "$TEMP_SUDOERS"
    echo -e "${GREEN}[install] Sudoers entry installed successfully${NC}"
else
    rm -f "$TEMP_SUDOERS"
    echo -e "${RED}[install] Failed to validate sudoers entry${NC}"
fi

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo -e "${GREEN}[install] Installation complete!${NC}"
echo ""
echo "Launch 'VM Tool' from:"
echo "  - Super/Activities menu"
echo "  - Terminal: vm-tool"
echo ""
echo "To uninstall:"
echo "  curl -sL https://raw.githubusercontent.com/yourusername/t-vm-utils/main/install.sh | bash -s -- uninstall"
