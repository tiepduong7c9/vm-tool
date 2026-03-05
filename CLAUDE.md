# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VM Tool is a bash-based utility for virtual machines running GNOME. It automatically scales monitors based on resolution and syncs system time using chrony. The project is distributed as a single-line installer via a curl script.

## Architecture

The project consists of three bash scripts:

1. **install.sh** - The main installer. Unusually, it embeds the entire vm-tool script content via heredoc (lines 65-175). This means changes to vm-tool must be reflected in both the standalone `vm-tool` file AND the heredoc section of `install.sh`.
2. **vm-tool** - Standalone version of the main script (for development/testing)
3. **uninstall.sh** - Standalone uninstaller (also embedded in install.sh)

### VM Tool Components

The vm-tool script performs two independent functions:

1. **Monitor Auto-scaling** (`vm-tool:10-81`)
   - Parses `gdctl show --modes` output to detect monitors and resolutions
   - Monitors >= 2500px width get 2x scale, others get 1x scale
   - Arranges monitors horizontally using `gdctl set`

2. **Time Sync** (`vm-tool:83-135`)
   - Checks `chronyc tracking` for system time drift
   - If drift exceeds 30 seconds, runs `chronyc makestep` via sudo
   - Requires passwordless sudo configuration (handled by installer)

### Installer Details

The installer creates:
- `~/.local/bin/vm-tool` - Main script (embedded heredoc)
- `~/.local/bin/vm-tool-wrapper` - Wrapper that sets DISPLAY/XAUTHORITY environment variables
- `~/.local/share/applications/vm-tool.desktop` - GNOME desktop entry
- `/etc/sudoers.d/vm-tool-chrony` - Passwordless sudo for chronyc commands

The wrapper script is necessary because gdctl requires DISPLAY and XAUTHORITY to be set when launched from the GNOME application menu.

## Development

When modifying vm-tool behavior, update both:
- The `vm-tool` file (for testing)
- The heredoc section in `install.sh` (lines 65-175, the `SCRIPT_EOF` section)

Test changes locally by running `./vm-tool` directly.

To test the full installer flow, use a temporary directory or the uninstall option:
```bash
./install.sh uninstall
./install.sh
```

## Dependencies

- `gdctl` - GNOME display configuration tool (for monitor scaling)
- `chrony` - NTP implementation (for time sync)
- `chronyc` - Command-line interface to chronyd
- GNOME desktop environment
- Ubuntu 25.10 or similar
