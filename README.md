# VM Tool

Auto-scale GNOME monitors and sync system time for VMs.

## Features

- **Auto-scale monitors**: Monitors with width ≥ 2500px get 2x scale, others get 1x
- **Time sync**: Automatically corrects system time drift using chrony (if drift > 30s)

## Installation

```bash
curl -sL https://raw.githubusercontent.com/yourusername/t-vm-utils/main/install.sh | bash
```

## Usage

- Launch **VM Tool** from the Super/Activities menu
- Or run in terminal: `vm-tool`

## Uninstallation

```bash
curl -sL https://raw.githubusercontent.com/yourusername/t-vm-utils/main/install.sh | bash -s -- uninstall
```

## Requirements

- GNOME desktop with `gdctl` (GNOME display configuration tool)
- `chrony` for time synchronization
- Ubuntu 25.10 (or similar)
