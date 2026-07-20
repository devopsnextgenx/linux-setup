#!/usr/bin/env bash

# Exit immediately if a critical command fails.
set -o pipefail

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Please run as root (sudo).\e[0m" >&2
  exit 1
fi

# --- COLOR DEFINITIONS ---
NC='\e[0m'              # No Color / Reset
BLUE='\e[34m'            # Menu Headers
GREEN='\e[32m'           # Data, Labels, Success, Decorations
RED='\e[31m'             # Errors, Removals, Directives/Alerts
YELLOW='\e[33m'          # Info, Warnings, Prompts

CONFIG_FILE="/etc/avahi/aliases.conf"
RUNNER_SCRIPT="/usr/local/bin/avahi-alias-runner.sh"
SYSTEMD_TEMPLATE="/etc/systemd/system/avahi-alias@.service"

echo -e "${YELLOW}[*] Step 1: Checking package requirements...${NC}"
if ! command -v avahi-publish &> /dev/null; then
    echo -e "${GREEN}[+] Installing utilities...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y avahi-utils avahi-daemon
    elif command -v dnf &> /dev/null; then
        dnf install -y avahi-tools avahi-daemon
    elif command -v pacman &> /dev/null; then
        pacman -S --noconfirm avahi
    else
        echo -e "${RED}[-] Unsupported package manager. Install 'avahi-utils' manually.${NC}" >&2
        exit 1
    fi
else
    echo -e "${GREEN}[✓] Avahi utilities detected.${NC}"
fi

# Ensure avahi-daemon is running before we proceed
systemctl enable --now avahi-daemon.service

echo -e "${YELLOW}[*] Step 2: Deploying backend runner script...${NC}"
cat << 'EOF' > "$RUNNER_SCRIPT"
#!/usr/bin/env bash
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
fi
exec /usr/bin/avahi-publish -a -R "$1" "$IP"
EOF

chmod +x "$RUNNER_SCRIPT"
echo -e "${GREEN}[✓] Runner script updated.${NC}"

echo -e "${YELLOW}[*] Step 3: Provisioning systemd template...${NC}"
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
    echo -e "${YELLOW}[*] Organizing existing configurations alphabetically...${NC}"
    sort -o "$CONFIG_FILE" "$CONFIG_FILE"
fi

# --- HELPER FUNCTIONS ---

print_current_config() {
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${BLUE}    CURRENT ACTIVE MDNS ALIASES           ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}[i] No domains configured.${NC}"
    else
        # Print actual domain names in green text
        while read -r line; do
            echo -e "  ${GREEN}• $line${NC}"
        done < "$CONFIG_FILE"
    fi
    echo -e "${GREEN}==========================================${NC}"
}

sync_and_apply() {
    echo -e "${YELLOW}[*] Reconciling background network alias services...${NC}"
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
            echo -e "${RED}[-] Stopping stale alias: $domain_name${NC}"
            systemctl disable --now "$instance" 2>/dev/null || true
        fi
    done

    # 2. Start services that ARE in the config list
    for domain in "${target_domains[@]}"; do
        if [ -n "$domain" ]; then
            echo -e "${GREEN}[+] Ensuring broadcast for: $domain${NC}"
            safe_instance=$(systemd-escape "$domain")
            systemctl enable --now "avahi-alias@${safe_instance}.service"
            systemctl restart "avahi-alias@${safe_instance}.service"
        fi
    done
    echo -e "${GREEN}[✓] Synchronization complete.${NC}"
}

# --- INITIAL AUTOSYNC ON RUN ---
sync_and_apply
sleep 1

# --- MAIN MENU & INPUT LOOPS ---

while true; do
    clear
    print_current_config
    echo -e "${BLUE}  MAIN MENU - AVAHI MDNS MANAGER${NC}"
    echo -e "  1) Add Hostnames (Bulk/Loop)"
    echo -e "  2) Remove Hostnames (Bulk/Loop)"
    echo -e "  3) Save & Sync Changes"
    echo -e "  4) Exit without changes"
    echo -e "${GREEN}------------------------------------------${NC}"
    echo -e "${YELLOW}" # Makes the query line stand out
    read -r -p "Select option [1-4]: " menu_choice
    echo -e "${NC}"

    case "$menu_choice" in
        1)
            while true; do
                clear
                print_current_config
                echo -e "${BLUE}--- ADD HOSTNAME MODE ---${NC}"
                echo -e "${RED}[DIR] Enter hostname(s). Separate multiples with commas.${NC}"
                echo -e "${YELLOW}[i] Example: pixtor-minis, plex-minis, jellyfin-minis${NC}"
                echo -e "${RED}[DIR] Press ENTER on a blank line to return to Main Menu.${NC}"
                echo -e "${GREEN}------------------------------------------${NC}"
                echo -e "${YELLOW}"
                read -r -p "Hostnames to ADD: " raw_input
                echo -e "${NC}"
                
                [ -z "$raw_input" ] && break

                while read -r item; do
                    clean=$(echo "$item" | tr -d '[:space:]')
                    [ -z "$clean" ] && continue
                    [[ ! "$clean" =~ \.local$ ]] && clean="${clean}.local"
                    
                    if grep -qFx "$clean" "$CONFIG_FILE" 2>/dev/null; then
                        echo -e "${RED}[!] '$clean' already exists.${NC}"
                    else
                        echo "$clean" >> "$CONFIG_FILE"
                        echo -e "${GREEN}[+] Added: $clean${NC}"
                    fi
                done <<< "$(echo "$raw_input" | tr ',' '\n')"
                
                sort -o "$CONFIG_FILE" "$CONFIG_FILE"
                echo -e "${YELLOW}Press Enter to continue or add more...${NC}"
                read -r
            done
            ;;
        2)
            while true; do
                clear
                print_current_config
                echo -e "${BLUE}--- REMOVE HOSTNAME MODE ---${NC}"
                echo -e "${RED}[DIR] Enter exact hostname(s) to remove. Separate multiples with commas.${NC}"
                echo -e "${RED}[DIR] Press ENTER on a blank line to return to Main Menu.${NC}"
                echo -e "${GREEN}------------------------------------------${NC}"
                echo -e "${YELLOW}"
                read -r -p "Hostnames to REMOVE: " raw_input
                echo -e "${NC}"
                
                [ -z "$raw_input" ] && break

                while read -r item; do
                    clean=$(echo "$item" | tr -d '[:space:]')
                    [ -z "$clean" ] && continue
                    [[ ! "$clean" =~ \.local$ ]] && clean="${clean}.local"
                    
                    if grep -qFx "$clean" "$CONFIG_FILE" 2>/dev/null; then
                        sed -i "/^${clean}$/d" "$CONFIG_FILE"
                        echo -e "${RED}[-–] Removed: $clean${NC}"
                    else
                        echo -e "${YELLOW}[!] '$clean' not found.${NC}"
                    fi
                done <<< "$(echo "$raw_input" | tr ',' '\n')"
                
                sort -o "$CONFIG_FILE" "$CONFIG_FILE"
                echo -e "${YELLOW}Press Enter to continue or remove more...${NC}"
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
