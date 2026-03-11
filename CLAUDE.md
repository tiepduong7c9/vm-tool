# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VM Tool is a bash-based utility for virtual machines running GNOME. It automatically scales monitors based on resolution and syncs system time using chrony. The project is distributed as a single-line installer via a curl script.

## Architecture

The project consists of a single installer script:

**install.sh** - The installer that embeds the entire vm-tool script content via heredoc (lines 65-175). To modify vm-tool behavior, edit the heredoc section in install.sh.

### VM Tool Components

The vm-tool script (embedded in install.sh heredoc) performs two independent functions:

1. **Monitor Auto-scaling** (lines 75-132 in heredoc)
   - Parses `gdctl show --modes` output to detect monitors and resolutions
   - Monitors >= 2500px width get 2x scale, others get 1x scale
   - Arranges monitors horizontally using `gdctl set`

2. **Time Sync** (lines 134-158 in heredoc)
   - Detects available time sync service (chrony/chronyd/systemd-timesyncd)
   - Restarts the detected service to force immediate time sync
   - Requires passwordless sudo configuration (handled by installer)

### Installer Details

The installer creates:
- `~/.local/bin/vm-tool` - Main script (embedded heredoc)
- `~/.local/bin/vm-tool-wrapper` - Wrapper that sets DISPLAY/XAUTHORITY environment variables
- `~/.local/share/applications/vm-tool.desktop` - GNOME desktop entry
- `/etc/sudoers.d/vm-tool-timesync` - Passwordless sudo for time sync service restart

The wrapper script is necessary because gdctl requires DISPLAY and XAUTHORITY to be set when launched from the GNOME application menu.

## Development

When modifying vm-tool behavior, edit the heredoc section in `install.sh` (the section between `cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'SCRIPT_EOF'` and `SCRIPT_EOF`).

To test changes after modifying the heredoc:
```bash
./install.sh uninstall
./install.sh
~/.local/bin/vm-tool
```

## Dependencies

- `gdctl` - GNOME display configuration tool (for monitor scaling)
- Time sync service: `chrony`, `chronyd`, or `systemd-timesyncd`
- GNOME desktop environment
- Ubuntu 25.10 or similar
