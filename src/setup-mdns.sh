#!/usr/bin/env bash

# Exit immediately ONLY if a foundational command fails. 
# We handle interactive loops and bad user inputs manually.
set -o pipefail

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

# Ensure config file exists
touch "$CONFIG_FILE"

# --- HELPER FUNCTIONS ---

print_current_config() {
    echo "=========================================="
    echo "    CURRENT ACTIVE MDNS ALIASES           "
    echo "=========================================="
    mapfile -t existing_domains < "$CONFIG_FILE"
    if [ ${#existing_domains[@]} -eq 0 ] || [ -z "${existing_domains[0]}" ]; then
        echo "[i] No domains are currently configured."
    else
        for dom in "${existing_domains[@]}"; do
            if [ -n "$dom" ]; then
                echo "  • $dom"
            fi
        done
    fi
    echo "=========================================="
}

add_domains_loop() {
    while true; do
        clear
        print_current_config
        echo "--- ADD HOSTNAME MODE ---"
        echo "Enter ONE hostname to add (or press ENTER on a blank line to return to main menu)."
        read -r -p "Enter hostname to ADD: " user_input
        
        clean_name=$(echo "$user_input" | tr -d '[:space:]')
        [ -z "$clean_name" ] && break
        
        # Format name cleanly
        if [[ ! "$clean_name" =~ \.local$ ]]; then
            clean_name="${clean_name}.local"
        fi

        # Duplicate check
        mapfile -t existing_domains < "$CONFIG_FILE"
        is_duplicate=false
        for ext_dom in "${existing_domains[@]}"; do
            if [ "$clean_name" = "$ext_dom" ]; then
                is_duplicate=true
                break
            fi
        done

        if [ "$is_duplicate" = true ]; then
            echo "[INFO] '$clean_name' is already active! Press Enter to continue..."
            read -r
        else
            echo "$clean_name" >> "$CONFIG_FILE"
            echo "[+] Appended: $clean_name"
            sleep 0.5
        fi
    done
}

remove_domains_loop() {
    while true; do
        clear
        print_current_config
        mapfile -t existing_domains < "$CONFIG_FILE"
        if [ ${#existing_domains[@]} -eq 0 ] || [ -z "${existing_domains[0]}" ]; then
            echo "[i] Nothing left to remove. Press Enter to return to main menu..."
            read -r
            break
        fi

        echo "--- REMOVE HOSTNAME MODE ---"
        echo "Enter the EXACT hostname name to remove (or press ENTER to return to main menu)."
        read -r -p "Enter hostname to REMOVE: " user_input
        
        clean_name=$(echo "$user_input" | tr -d '[:space:]')
        [ -z "$clean_name" ] && break

        if [[ ! "$clean_name" =~ \.local$ ]]; then
            clean_name="${clean_name}.local"
        fi

        # Verification check
        if grep -Fq "$clean_name" "$CONFIG_FILE"; then
            # Re-write file excluding the deleted element safely
            sed -i "/^${clean_name}$/d" "$CONFIG_FILE"
            echo "[-] Removed configuration for: $clean_name"
            sleep 0.5
        else
            echo "[WARN] Domain '$clean_name' not found in active records. Press Enter to retry..."
            read -r
        fi
    done
}

sync_and_apply() {
    echo "[*] Syncing live backend network alias services..."
    mapfile -t target_domains < "$CONFIG_FILE"
    
    # Tear down services that were deleted in the interface
    active_instances=$(systemctl list-units --type=service --state=running "avahi-alias@*" --no-legend | awk '{print $1}')
    for instance in $active_instances; do
        domain_name=$(echo "$instance" | sed -n 's/.*@\(.*\)\.service/\1/p')
        if [[ ! " ${target_domains[*]} " =~ " ${domain_name} " ]]; then
            echo "[-] Stopping stale alias broadcast: $domain_name"
            systemctl disable --now "$instance" || true
        fi
    done

    # Start up all verified domains left in the mapping config
    for domain in "${target_domains[@]}"; do
        if [ -n "$domain" ]; then
            systemctl enable --now "avahi-alias@${domain}.service"
        fi
    done
    echo "[✓] Network broadcasts are live and fully synchronized."
}

# --- MAIN CONTROL MENU LOOP ---

while true; do
    clear
    print_current_config
    echo "  MAIN MENU - AVAHI MDNS MANAGER"
    echo "  1) Add Hostnames"
    echo "  2) Remove Hostnames"
    echo "  3) Save Changes & Exit"
    echo "  4) Abort (Discard Menu Changes)"
    echo "------------------------------------------"
    read -r -p "Select an option [1-4]: " menu_choice

    case "$menu_choice" in
        1)
            add_domains_loop
            ;;
        2)
            remove_domains_loop
            ;;
        3)
            clear
            sync_and_apply
            exit 0
            ;;
        4)
            echo "[i] Aborted. No changes applied to live services."
            exit 0
            ;;
        *)
            echo "[!] Invalid selection. Press Enter to retry..."
            read -r
            ;;
    esac
done
