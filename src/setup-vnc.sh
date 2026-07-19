#!/bin/bash

# =====================================================================
# 1. Idempotent System Setup (Requires sudo if packages are missing)
# =====================================================================
REQUIRED_PKGS=("tigervnc-standalone-server" "tigervnc-common")
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
else
    echo "System dependencies are already installed. Skipping apt..."
fi

# =====================================================================
# 2. User-Space Sanity Checks (Must NOT run the rest as root)
# =====================================================================
if [ "$EUID" -eq 0 ]; then
   echo "System dependencies verified."
   echo "Please do not run the actual setup script as root. Run it as the regular user."
   exit 1
fi

USER_HOME=$HOME
VNC_DIR="$USER_HOME/.vnc"

# Create .vnc directory idempotently
if [ ! -d "$VNC_DIR" ]; then
    mkdir -p "$VNC_DIR"
    chmod 700 "$VNC_DIR"
fi

# =====================================================================
# 3. Idempotent GNOME Configuration Files
# =====================================================================

# Write xstartup if missing or modified
TARGET_XSTARTUP=$(cat << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_CURRENT_DESKTOP="GNOME"
export XDG_MENU_PREFIX="gnome-"
exec gnome-session
EOF
)

if [ ! -f "$VNC_DIR/xstartup" ] || [ "$(cat "$VNC_DIR/xstartup")" != "$TARGET_XSTARTUP" ]; then
    echo "Configuring xstartup for GNOME..."
    echo "$TARGET_XSTARTUP" > "$VNC_DIR/xstartup"
    chmod +x "$VNC_DIR/xstartup"
fi

# Write config if missing or modified (using the modern Debian key-value format)
TARGET_CONFIG=$(cat << 'EOF'
localhost=no
geometry=1920x1080
depth=24
EOF
)

if [ ! -f "$VNC_DIR/config" ] || [ "$(cat "$VNC_DIR/config")" != "$TARGET_CONFIG" ]; then
    echo "Updating TigerVNC configuration options..."
    echo "$TARGET_CONFIG" > "$VNC_DIR/config"
fi

# Initialize VNC Password only if it doesn't exist
if [ ! -f "$VNC_DIR/passwd" ]; then
    echo "Setting up your VNC access password..."
    tigervncpasswd
else
    echo "VNC password profile already verified."
fi

# =====================================================================
# 4. Display Allocation & Port Orchestration
# =====================================================================
DISPLAY_NUM=$((UID - 1000))
if [ $DISPLAY_NUM -le 0 ]; then
    DISPLAY_NUM=1
fi

PORT=$((5900 + DISPLAY_NUM))
IP_ADDR=$(hostname -I | awk '{print $1}')

# Idempotent process management: Kill matching instance if running, then spawn fresh
if tigervncserver -list | grep -q ":$DISPLAY_NUM"; then
    echo "Existing VNC server detected on display :$DISPLAY_NUM. Restarting..."
    tigervncserver -kill ":$DISPLAY_NUM" > /dev/null 2>&1
fi

echo "Starting TigerVNC server on display :$DISPLAY_NUM..."
tigervncserver ":$DISPLAY_NUM" -localhost no

echo "========================================================="
echo " VNC Server is successfully running!"
echo "========================================================="
echo "Connection Address: $IP_ADDR:$PORT (or $IP_ADDR:$DISPLAY_NUM)"
echo "========================================================="