#!/usr/bin/env bash

# Exit immediately if a critical command fails.
set -o pipefail

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo)." >&2
  exit 1
fi

CONFIG_FILE="/etc/avahi/aliases.conf"
RUNNER_SCRIPT="/usr/local/bin/avahi-alias-runner.sh"
SYSTEMD_TEMPLATE="/etc/systemd/system/avahi-alias@.service"

echo "[*] Step 1: Checking package requirements..."
if ! command -v avahi-publish &> /dev/null; then
    echo "[+] Installing utilities..."
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
    echo "[✓] Avahi utilities detected."
fi

# Ensure avahi-daemon is running before we proceed
systemctl enable --now avahi-daemon.service

echo "[*] Step 2: Deploying backend runner script..."
cat << 'EOF' > "$RUNNER_SCRIPT"
#!/usr/bin/env bash
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
fi
exec /usr/bin/avahi-publish -a -R "$1" "$IP"
EOF

chmod +x "$RUNNER_SCRIPT"
echo "[✓] Runner script updated."

echo "[*] Step 3: Provisioning systemd template..."
cat << 'EOF' > "$SYSTEMD_TEMPLATE"
[Unit]
Description=Publish %I via mDNS ZeroConf Alias
After=avahi-daemon.service network-online.target
BindsTo=avahi-daemon.service

[Service]
Type=simple
ExecStart=/usr/local/bin/avahi-alias-runner.sh %I
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Ensure file exists, then immediately sort any pre-existing unorganized lines
touch "$CONFIG_FILE"
if [ -s "$CONFIG_FILE" ]; then
    echo "[*] Organizing existing configurations alphabetically..."
    sort -o "$CONFIG_FILE" "$CONFIG_FILE"
fi

# --- HELPER FUNCTIONS ---

print_current_config() {
    echo "=========================================="
    echo "    CURRENT ACTIVE MDNS ALIASES           "
    echo "=========================================="
    if [ ! -s "$CONFIG_FILE" ]; then
        echo "[i] No domains configured."
    else
        cat "$CONFIG_FILE" | sed 's/^/  • /'
    fi
    echo "=========================================="
}

sync_and_apply() {
    echo "[*] Reconciling background network alias services..."
    mapfile -t target_domains < "$CONFIG_FILE"

    # 1. Stop services that are NO LONGER in the config list
    active_instances=$(systemctl list-units --type=service --all "avahi-alias@*" --no-legend | awk '{print $1}')
    
    for instance in $active_instances; do
        escaped_name=$(echo "$instance" | sed -n 's/avahi-alias@\(.*\)\.service/\1/p')
        [ -z "$escaped_name" ] && continue
        
        domain_name=$(systemd-escape --unescape "$escaped_name")
        
        found=false
        for target in "${target_domains[@]}"; do
            if [[ "$target" == "$domain_name" ]]; then
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            echo "[-] Stopping stale alias: $domain_name"
            systemctl disable --now "$instance" 2>/dev/null || true
        fi
    done

    # 2. Start services that ARE in the config list
    for domain in "${target_domains[@]}"; do
        if [ -n "$domain" ]; then
            echo "[+] Ensuring broadcast for: $domain"
            safe_instance=$(systemd-escape "$domain")
            systemctl enable --now "avahi-alias@${safe_instance}.service"
            systemctl restart "avahi-alias@${safe_instance}.service"
        fi
    done
    echo "[✓] Synchronization complete."
}

# --- INITIAL AUTOSYNC ON RUN ---
sync_and_apply
sleep 1

# --- MAIN MENU & INPUT LOOPS ---

while true; do
    clear
    print_current_config
    echo "  MAIN MENU - AVAHI MDNS MANAGER"
    echo "  1) Add Hostnames (Bulk/Loop)"
    echo "  2) Remove Hostnames (Bulk/Loop)"
    echo "  3) Save & Sync Changes"
    echo "  4) Exit without changes"
    echo "------------------------------------------"
    read -r -p "Select option [1-4]: " menu_choice

    case "$menu_choice" in
        1)
            while true; do
                clear
                print_current_config
                echo "--- ADD HOSTNAME MODE ---"
                echo "Enter hostname(s). Separate multiples with commas."
                echo "Example: pixtor-minis, plex-minis, jellyfin-minis"
                echo "Press ENTER on a blank line to return to Main Menu."
                echo "------------------------------------------"
                read -r -p "Hostnames to ADD: " raw_input
                
                [ -z "$raw_input" ] && break

                # Using a Here-String ensures loop runs in current shell context, avoiding subshell traps
                while read -r item; do
                    clean=$(echo "$item" | tr -d '[:space:]')
                    [ -z "$clean" ] && continue
                    [[ ! "$clean" =~ \.local$ ]] && clean="${clean}.local"
                    
                    if grep -qFx "$clean" "$CONFIG_FILE" 2>/dev/null; then
                        echo "[!] '$clean' already exists."
                    else
                        echo "$clean" >> "$CONFIG_FILE"
                        echo "[+] Added: $clean"
                    fi
                done <<< "$(echo "$raw_input" | tr ',' '\n')"
                
                sort -o "$CONFIG_FILE" "$CONFIG_FILE"
                echo "Press Enter to continue or add more..."
                read -r
            done
            ;;
        2)
            while true; do
                clear
                print_current_config
                echo "--- REMOVE HOSTNAME MODE ---"
                echo "Enter exact hostname(s) to remove. Separate multiples with commas."
                echo "Press ENTER on a blank line to return to Main Menu."
                echo "------------------------------------------"
                read -r -p "Hostnames to REMOVE: " raw_input
                
                [ -z "$raw_input" ] && break

                while read -r item; do
                    clean=$(echo "$item" | tr -d '[:space:]')
                    [ -z "$clean" ] && continue
                    [[ ! "$clean" =~ \.local$ ]] && clean="${clean}.local"
                    
                    if grep -qFx "$clean" "$CONFIG_FILE" 2>/dev/null; then
                        sed -i "/^${clean}$/d" "$CONFIG_FILE"
                        echo "[-] Removed: $clean"
                    else
                        echo "[!] '$clean' not found."
                    fi
                done <<< "$(echo "$raw_input" | tr ',' '\n')"
                
                sort -o "$CONFIG_FILE" "$CONFIG_FILE"
                echo "Press Enter to continue or remove more..."
                read -r
            done
            ;;
        3)
            sync_and_apply
            exit 0
            ;;
        4)
            exit 0
            ;;
    esac
done
