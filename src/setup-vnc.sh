#!/bin/bash

# =====================================================================
# 1. System Dependency Setup
# =====================================================================
REQUIRED_PKGS=("tigervnc-standalone-server" "tigervnc-common" "dbus-x11")
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "Dependencies missing: ${MISSING_PKGS[*]}. Elevating privileges to install..."
    sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
    if [ $? -ne 0 ]; then
        echo "Failed to install required packages. Exiting."
        exit 1
    fi
fi

# =====================================================================
# 2. User-Space Environment Provisioning (Must NOT run as root)
# =====================================================================
if [ "$EUID" -eq 0 ]; then
   echo "System components verified."
   echo "Please do not execute this setup process as root. Run it as the regular user."
   exit 1
fi

CURRENT_USER=$USER
USER_HOME=$HOME
VNC_DIR="$USER_HOME/.vnc"
USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"

# Calculate display variables
DISPLAY_NUM=$((UID - 1000))
if [ $DISPLAY_NUM -le 0 ]; then
    DISPLAY_NUM=1
fi
PORT=$((5900 + DISPLAY_NUM))
IP_ADDR=$(hostname -I | awk '{print $1}')

# Clean up the legacy broken system-level service if it exists
LEGACY_SYSTEM_SERVICE="/etc/systemd/system/vncserver-${CURRENT_USER}.service"
if [ -f "$LEGACY_SYSTEM_SERVICE" ]; then
    echo "Cleaning up legacy broken system service..."
    sudo systemctl disable "vncserver-${CURRENT_USER}.service" --now > /dev/null 2>&1
    sudo rm -f "$LEGACY_SYSTEM_SERVICE"
    sudo systemctl daemon-reload
fi

# Ensure directories exist
mkdir -p "$VNC_DIR" && chmod 700 "$VNC_DIR"
mkdir -p "$USER_SYSTEMD_DIR"

# Modern, simplified xstartup forcing software rendering for headless GNOME
TARGET_XSTARTUP=$(cat << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Force GNOME to use CPU/Software rendering instead of looking for a hardware GPU
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_CURRENT_DESKTOP="GNOME"
export XDG_MENU_PREFIX="gnome-"

exec gnome-session
EOF
)

if [ ! -f "$VNC_DIR/xstartup" ] || [ "$(cat "$VNC_DIR/xstartup")" != "$TARGET_XSTARTUP" ]; then
    echo "Configuring xstartup sequence for GNOME..."
    echo "$TARGET_XSTARTUP" > "$VNC_DIR/xstartup"
    chmod +x "$VNC_DIR/xstartup"
fi

# Configuration parameters
TARGET_CONFIG=$(cat << 'EOF'
localhost=no
geometry=1920x1080
depth=24
EOF
)

if [ ! -f "$VNC_DIR/config" ] || [ "$(cat "$VNC_DIR/config")" != "$TARGET_CONFIG" ]; then
    echo "Updating configuration parameters..."
    echo "$TARGET_CONFIG" > "$VNC_DIR/config"
fi

# Guard password generation
if [ ! -f "$VNC_DIR/passwd" ]; then
    echo "Setting up your personal security credential profile..."
    tigervncpasswd
else
    echo "Authentication profile already verified."
fi

# Ensure user lingering is enabled so the user systemd instance boots up with the machine
if [ ! -f "/var/lib/systemd/linger/${CURRENT_USER}" ]; then
    echo "Enabling systemd user lingering for boot persistence..."
    sudo loginctl enable-linger "${CURRENT_USER}"
fi

# =====================================================================
# 3. User-Level Systemd Service Generation
# =====================================================================
USER_SERVICE_FILE="${USER_SYSTEMD_DIR}/vncserver.service"
TARGET_USER_SERVICE=$(cat << EOF
[Unit]
Description=Remote desktop service (VNC) running in user slice
After=default.target

[Service]
Type=forking
ExecStartPre=-/usr/bin/tigervncserver -kill :${DISPLAY_NUM} > /dev/null 2>&1
ExecStart=/usr/bin/tigervncserver :${DISPLAY_NUM} -localhost no -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/tigervncserver -kill :${DISPLAY_NUM}

[Install]
WantedBy=default.target
EOF
)

# Deploy the user-level service descriptor
if [ ! -f "$USER_SERVICE_FILE" ] || [ "$(cat "$USER_SERVICE_FILE")" != "$TARGET_USER_SERVICE" ]; then
    echo "Deploying user-level systemd service configuration..."
    echo "$TARGET_USER_SERVICE" > "$USER_SERVICE_FILE"
    systemctl --user daemon-reload
fi

# =====================================================================
# 4. Persistence Orchestration & Lifecycle Control
# =====================================================================
echo "Registering user-level persistent boot sequence..."

# Enable and restart via the user instance manager
systemctl --user daemon-reload
systemctl --user enable vncserver.service
systemctl --user restart vncserver.service

if systemctl --user is-active --quiet vncserver.service; then
    echo "========================================================="
    echo " Persistent VNC Server Configured & Running Safely!"
    echo "========================================================="
    echo "Connection Address: $IP_ADDR:$PORT (or $IP_ADDR:$DISPLAY_NUM)"
    echo "This session will automatically start when the system boots,"
    echo "even if no users are logged in locally."
    echo "========================================================="
else
    echo "ERROR: User service failed to start. Please run: 'systemctl --user status vncserver.service' to diagnose."
fi