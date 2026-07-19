#!/bin/bash

# Ensure script isn't run as root (it must be run by the actual user)
if [ "$EUID" -eq 0 ]; then
   echo "Please do not run this script as root. Run it as the user who needs VNC access."
   exit 1
fi

USER_HOME=$HOME
VNC_DIR="$USER_HOME/.vnc"

# 1. Create .vnc directory if it doesn't exist
mkdir -p "$VNC_DIR"
chmod 700 "$VNC_DIR"

# 2. Create the xstartup file to launch GNOME desktop
cat << 'EOF' > "$VNC_DIR/xstartup"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Set up the X11 environment for GNOME
export XDG_CURRENT_DESKTOP="GNOME"
export XDG_MENU_PREFIX="gnome-"

# Launch the standard GNOME session
exec gnome-session
EOF

chmod +x "$VNC_DIR/xstartup"

chmod +x "$VNC_DIR/xstartup"

# 3. Create basic config file to allow public connections (-localhost no)
cat << 'EOF' > "$VNC_DIR/config"
$localhost = "no";
$geometry = "1920x1080";
$depth = "24";
EOF

# 4. Set VNC Password if it doesn't exist
if [ ! -f "$VNC_DIR/passwd" ]; then
    echo "Setting up your VNC access password..."
    vncpasswd
else
    echo "VNC password already exists. Skipping..."
fi

# 5. Calculate a unique display number based on UID to avoid collisions
# (e.g., UID 1001 becomes Display :1, Port 5901)
DISPLAY_NUM=$((UID - 1000))
if [ $DISPLAY_NUM -le 0 ]; then
    DISPLAY_NUM=1
fi

# Kill any existing geometry on this specific display first
vncserver -kill ":$DISPLAY_NUM" > /dev/null 2>&1

# 6. Start the TigerVNC server listening on all interfaces
echo "Starting TigerVNC server on display :$DISPLAY_NUM..."
vncserver ":$DISPLAY_NUM" -localhost no

# 7. Output connection details for the user
PORT=$((5900 + DISPLAY_NUM))
IP_ADDR=$(hostname -I | awk '{print $1}')

echo "========================================================="
echo " VNC Server is successfully running!"
echo "========================================================="
echo "You can connect using any VNC Client (like RealVNC or TigerVNC Viewer)."
echo "Address: $IP_ADDR:$PORT (or $IP_ADDR:$DISPLAY_NUM)"
echo "========================================================="