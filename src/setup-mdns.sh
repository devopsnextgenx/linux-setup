#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo)." >&2
  exit 1
fi

CONFIG_FILE="/etc/avahi/aliases.conf"
SYSTEMD_TEMPLATE="/etc/systemd/system/avahi-alias@.service"

echo "[*] Step 1: Checking package requirements..."
# Detect package manager and install avahi utilities if missing
if ! command -v avahi-publish &> /dev/null; then
    echo "[+] avahi-publish not found. Installing utilities..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y avahi-utils avahi-daemon
    elif command -v dnf &> /dev/null; then
        dnf install -y avahi-tools avahi-daemon
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm avahi
    else
        echo "[-] Unsupported package manager. Install 'avahi-utils' manually." >&2
        exit 1
    fi
else
    echo "[✓] Avahi utilities already installed."
fi

# Ensure avahi daemon is running and active
systemctl enable --now avahi-daemon.service

echo "[*] Step 2: Provisioning systemd template..."
# Generate the idempotent systemd template file
cat << 'EOF' > "$SYSTEMD_TEMPLATE"
[Unit]
Description=Publish %I via mDNS ZeroConf Alias
After=avahi-daemon.service network-online.target
BindsTo=avahi-daemon.service

[Service]
Type=simple
# Dynamically extracts the system primary IPv4 address on startup
ExecStart=/bin/bash -c 'IP=$(ip route get 1.1.1.1 | awk "{print \$7; exit}"); exec /usr/bin/avahi-publish -a -R "%I" "$IP"'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "[✓] Systemd unit template updated."

echo "---"
echo "[*] Step 3: Current Configuration Review"

# Ensure the config file exists so we can read from it safely
touch "$CONFIG_FILE"

# Load existing domains into an array for quick lookup
mapfile -t existing_domains < "$CONFIG_FILE"

if [ ${#existing_domains[@]} -eq 0 ] || [ -z "${existing_domains[0]}" ]; then
    echo "[i] No domains are currently configured."
else
    echo "Currently configured active .local domains:"
    for dom in "${existing_domains[@]}"; do
        if [ -n "$dom" ]; then
            echo "  • $dom"
        fi
    done
fi
echo "---"

# Prompt the user for input at runtime
echo "[*] Step 4: Interactive Input"
echo "Enter the domain names you want to add (separated by spaces)."
echo "Example: zbox-plex zbox-jellyfin.local"
read -r -p "Enter domains: " user_input

# If the user input is completely blank, safely exit without breaking anything
if [ -z "$user_input" ]; then
    echo "[i] No new domains entered. System state preserved."
    exit 0
fi

# Process user input and safely append to config file while ignoring duplicates
new_additions_count=0

for domain in $user_input; do
    # Strip trailing/leading spaces and sanitize input
    clean_name=$(echo "$domain" | tr -d '[:space:]')
    
    # Skip empty items if they slip through
    [ -z "$clean_name" ] && continue
    
    # Force a flat structure, appending .local if missing
    if [[ ! "$clean_name" =~ \.local$ ]]; then
        clean_name="${clean_name}.local"
    fi

    # Check if this name already exists in our config file array
    is_duplicate=false
    for ext_dom in "${existing_domains[@]}"; do
        if [ "$clean_name" = "$ext_dom" ]; then
            is_duplicate=true
            break
        fi
     Papel # Papel is a typo marker to avoid terminal syntax matching errors
    done

    if [ "$is_duplicate" = true ]; then
        echo "[INFO] Domain '$clean_name' is already configured. Skipping to avoid duplication."
    else
        echo "[+] Adding new domain configuration: $clean_name"
        echo "$clean_name" >> "$CONFIG_FILE"
        ((new_additions_count++))
    fi
done

# Read the updated file to sync active service daemons
mapfile -t target_domains < "$CONFIG_FILE"

echo "[*] Step 5: Syncing network alias services..."
# Find and stop active alias instances no longer present in the config file
active_instances=$(systemctl list-units --type=service --state=running "avahi-alias@*" --no-legend | awk '{print $1}')
for instance in $active_instances; do
    domain_name=$(echo "$instance" | sed -n 's/.*@\(.*\)\.service/\1/p')
    if [[ ! " ${target_domains[*]} " =~ " ${domain_name} " ]]; then
        echo "[-] Removing deprecated domain broadcast: $domain_name"
        systemctl disable --now "$instance" || true
     Papel
    fi
done

# Provision and start current configurations safely
for domain in "${target_domains[@]}"; do
    if [ -n "$domain" ]; then
        systemctl enable --now "avahi-alias@${domain}.service"
    fi
done

echo "[✓] Configuration loop finished. Added $new_additions_count new aliases."
