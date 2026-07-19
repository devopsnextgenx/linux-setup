#!/bin/bash

# =====================================================================
# 1. System Dependency Setup (Requires sudo if packages/utilities are missing)
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
# 2. Idempotent Systemd Unit Template Creation
# =====================================================================
SERVICE_TEMPLATE="/etc/systemd/system/vncserver@.service"
TARGET_SERVICE_CONTENT=$(cat << 'EOF'
[Unit]
Description=Remote desktop service (VNC) for %i
After=syslog.target network.target

[Service]
Type=forking
User=%i
Group=%i
WorkingDirectory=/home/%i
ExecStartPre=-/usr/bin/tigervncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/tigervncserver :%i -localhost no -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/tigervncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF
)

# Deploy the systemd template only if it doesn't match or exist
if [ ! -f "$SERVICE_TEMPLATE" ] || [ "$(cat "$SERVICE_TEMPLATE")" != "$TARGET_SERVICE_CONTENT" ]; then
    echo "Deploying system-wide persistent systemd service template..."
    echo "$TARGET_SERVICE_CONTENT" | sudo tee "$SERVICE_TEMPLATE" > /dev/null
    sudo systemctl daemon-reload
fi

# =====================================================================
# 3. User-Space Environment Provisioning (Must NOT run as root)
# =====================================================================
if [ "$EUID" -eq 0 ]; then
   echo "System components verified."
   echo "Please do not execute this setup process as root. Run it as the regular user."
   exit 1
fi

CURRENT_USER=$USER
USER_HOME=$HOME
VNC_DIR="$USER_HOME/.vnc"

if [ ! -d "$VNC_DIR" ]; then
    mkdir -p "$VNC_DIR"
    chmod 700 "$VNC_DIR"
fi

# Write xstartup tailored for headless, persistent GNOME sessions via dbus
TARGET_XSTARTUP=$(cat << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_CURRENT_DESKTOP="GNOME"
export XDG_MENU_PREFIX="gnome-"
export GNOME_SHELL_SESSION_MODE="ubuntu"

if [ -x /usr/bin/dbus-launch ]; then
  exec dbus-launch --exit-with-session gnome-session
else
  exec gnome-session
fi
EOF
)

if [ ! -f "$VNC_DIR/xstartup" ] || [ "$(cat "$VNC_DIR/xstartup")" != "$TARGET_XSTARTUP" ]; then
    echo "Configuring persistent xstartup sequence for GNOME..."
    echo "$TARGET_XSTARTUP" > "$VNC_DIR/xstartup"
    chmod +x "$VNC_DIR/xstartup"
fi

# Modern Debian TigerVNC configuration options
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

# =====================================================================
# 4. Persistence Orchestration & Lifecycle Control
# =====================================================================
DISPLAY_NUM=$((UID - 1000))
if [ $DISPLAY_NUM -le 0 ]; then
    DISPLAY_NUM=1
fi

PORT=$((5900 + DISPLAY_NUM))
IP_ADDR=$(hostname -I | awk '{print $1}')

echo "Registering persistent boot sequence for display :$DISPLAY_NUM..."

# Safely stop existing instances before refreshing service states
if sudo systemctl is-active --quiet "vncserver@$DISPLAY_NUM"; then
    echo "Restarting service worker..."
    sudo systemctl restart "vncserver@$DISPLAY_NUM"
else
    sudo systemctl enable "vncserver@$DISPLAY_NUM" --now
fi

echo "========================================================="
echo " Persistent VNC Server Configured & Running!"
echo "========================================================="
echo "Connection Address: $IP_ADDR:$PORT (or $IP_ADDR:$DISPLAY_NUM)"
echo "This session will automatically start when the system boots,"
echo "even if no users are logged in locally."
echo "========================================================="