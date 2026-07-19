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

systemctl enable --now avahi-daemon.service

echo "[*] Step 2: Provisioning systemd template..."
cat << 'EOF' > "$SYSTEMD_TEMPLATE"
[Unit]
Description=Publish %I via mDNS ZeroConf Alias
After=avahi-daemon.service network-online.target
BindsTo=avahi-daemon.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'IP=$(ip route get 1.1.1.1 | awk "{print \$7; exit}"); exec /usr/bin/avahi-publish -a -R "%I" "$IP"'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "[✓] Systemd unit template updated."

# Ensure the config file exists so we can read from it safely
touch "$CONFIG_FILE"
new_additions_count=0

# Loop the interactive menu until the user decides to exit
while true; do
    echo "---"
    echo "[*] Step 3: Current Configuration Review"
    
    # Reload existing domains into an array fresh on each loop iteration
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

    echo "[*] Step 4: Interactive Input Loop"
    echo "Enter domain names (separated by spaces) to add them."
    echo "Type 'exit' or press Enter on an empty line to finish and apply changes."
    read -r -p "Enter domains: " user_input

    # Clean the input to check for exit keywords
    exit_check=$(echo "$user_input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ -z "$user_input" ] || [ "$exit_check" = "exit" ]; then
        echo "[*] Exiting input loop. Finalizing setup..."
        break
    fi

    # Process individual entries from the line input
    for domain in $user_input; do
        clean_name=$(echo "$domain" | tr -d '[:space:]')
        [ -z "$clean_name" ] && continue
        
        # Guard against accidentally adding the literal word 'exit' if mixed in a list
        if [ "$(echo "$clean_name" | tr '[:upper:]' '[:lower:]')" = "exit" ]; then
            continue
        fi

        # Force trailing .local
        if [[ ! "$clean_name" =~ \.local$ ]]; then
            clean_name="${clean_name}.local"
        fi

        # Check for duplicates against the updated config file array
        is_duplicate=false
        for ext_dom in "${existing_domains[@]}"; do
            if [ "$clean_name" = "$ext_dom" ]; then
                is_duplicate=true
                break
            fi
        done

        if [ "$is_duplicate" = true ]; then
            echo "[INFO] Domain '$clean_name' is already configured. Skipping."
        else
            echo "[+] Appending new domain configuration: $clean_name"
            echo "$clean_name" >> "$CONFIG_FILE"
            ((new_additions_count++))
            
            # Re-read file immediately so consecutive inputs in the same turn catch back-to-back duplicates
            mapfile -t existing_domains < "$CONFIG_FILE"
        fi
    done
done

# Read final state of target mappings
mapfile -t target_domains < "$CONFIG_FILE"

echo "[*] Step 5: Syncing network alias services..."
active_instances=$(systemctl list-units --type=service --state=running "avahi-alias@*" --no-legend | awk '{print $1}')
for instance in $active_instances; do
    domain_name=$(echo "$instance" | sed -n 's/.*@\(.*\)\.service/\1/p')
    if [[ ! " ${target_domains[*]} " =~ " ${domain_name} " ]]; then
        echo "[-] Removing deprecated domain broadcast: $domain_name"
        systemctl disable --now "$instance" || true
    fi
done

for domain in "${target_domains[@]}"; do
    if [ -n "$domain" ]; then
        systemctl enable --now "avahi-alias@${domain}.service"
    fi
done

echo "[✓] Configuration completed successfully. Added a total of $new_additions_count new network aliases."
