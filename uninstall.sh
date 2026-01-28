#!/bin/bash
# Uninstall vm-tool

set -e

SCRIPT_NAME="vm-tool"
WRAPPER_NAME="vm-tool-wrapper"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
SUDOERS_FILE="/etc/sudoers.d/vm-tool-chrony"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[uninstall] Uninstalling vm-tool...${NC}"

# Remove installed scripts
if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
    echo -e "${BLUE}[uninstall] Removing $INSTALL_DIR/$SCRIPT_NAME${NC}"
    rm -f "$INSTALL_DIR/$SCRIPT_NAME"
else
    echo -e "${YELLOW}[uninstall] Script not found in $INSTALL_DIR${NC}"
fi

if [[ -f "$INSTALL_DIR/$WRAPPER_NAME" ]]; then
    echo -e "${BLUE}[uninstall] Removing wrapper script${NC}"
    rm -f "$INSTALL_DIR/$WRAPPER_NAME"
fi

# Remove desktop entry
if [[ -f "$DESKTOP_DIR/vm-tool.desktop" ]]; then
    echo -e "${BLUE}[uninstall] Removing desktop entry...${NC}"
    rm -f "$DESKTOP_DIR/vm-tool.desktop"
else
    echo -e "${YELLOW}[uninstall] Desktop entry not found${NC}"
fi

# Update desktop database
echo -e "${BLUE}[uninstall] Updating desktop database...${NC}"
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# Remove sudoers file
if [[ -f "$SUDOERS_FILE" ]]; then
    echo -e "${BLUE}[uninstall] Removing sudoers entry...${NC}"
    sudo rm -f "$SUDOERS_FILE"
else
    echo -e "${YELLOW}[uninstall] Sudoers file not found${NC}"
fi

echo -e "${GREEN}[uninstall] Uninstallation complete!${NC}"
