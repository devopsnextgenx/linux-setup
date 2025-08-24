#!/bin/bash

# SMB Auto-Mount Setup Script
# Configures automatic mounting of SMB share on Debian/Ubuntu

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Default configuration variables
DEFAULT_SMB_HOST="zbox.local"
DEFAULT_SMB_SHARE="data"
DEFAULT_MOUNT_POINT="/media/zbox"
DEFAULT_USERNAME="admn"
DEFAULT_USER_ID="1000"
DEFAULT_GROUP_ID="1000"

# Variables to be set by user input
SMB_HOST=""
SMB_SHARE=""
MOUNT_POINT=""
CREDENTIALS_FILE=""
USERNAME=""
PASSWORD=""
USER_ID=""
GROUP_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sudo is available and test sudo access
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        log_error "sudo is not installed. Please install sudo or run as root."
        exit 1
    fi
    
    log_info "This script requires sudo privileges for system configuration"
    log_info "You may be prompted for your password for sudo commands"
    
    # Test sudo access
    if ! sudo -v; then
        log_error "Unable to obtain sudo privileges"
        exit 1
    fi
    
    log_info "Sudo access confirmed"
}

# Prompt for all configuration details
prompt_configuration() {
    log_info "SMB Auto-Mount Configuration"
    echo "Press Enter to use default values shown in brackets"
    echo
    
    # SMB Host
    read -p "SMB Host [$DEFAULT_SMB_HOST]: " input_host
    SMB_HOST="${input_host:-$DEFAULT_SMB_HOST}"
    
    # SMB Share
    read -p "SMB Share name [$DEFAULT_SMB_SHARE]: " input_share
    SMB_SHARE="${input_share:-$DEFAULT_SMB_SHARE}"
    
    # Mount Point
    read -p "Local mount point [$DEFAULT_MOUNT_POINT]: " input_mount
    MOUNT_POINT="${input_mount:-$DEFAULT_MOUNT_POINT}"
    
    # Set credentials file based on share name for uniqueness
    CREDENTIALS_FILE="/etc/samba/credentials-$(echo "$SMB_SHARE" | tr '/' '_')"
    
    # Username
    read -p "SMB Username [$DEFAULT_USERNAME]: " input_username
    USERNAME="${input_username:-$DEFAULT_USERNAME}"
    
    # Password (hidden input with confirmation)
    while [[ -z "$PASSWORD" ]]; do
        read -s -p "SMB Password: " PASSWORD
        echo
        if [[ -z "$PASSWORD" ]]; then
            log_warn "Password cannot be empty. Please try again."
        fi
    done
    
    # Confirm password
    read -s -p "Confirm password: " password_confirm
    echo
    
    if [[ "$PASSWORD" != "$password_confirm" ]]; then
        log_error "Passwords do not match. Exiting."
        exit 1
    fi
    
    # Get current user info for proper ownership
    if [[ -z "$USER_ID" ]]; then
        USER_ID=$(id -u)
    fi
    if [[ -z "$GROUP_ID" ]]; then
        GROUP_ID=$(id -g)
    fi
    
    # Allow override of User/Group IDs if needed
    read -p "User ID for mount ownership [$USER_ID]: " input_uid
    if [[ -n "$input_uid" ]]; then
        USER_ID="$input_uid"
    fi
    
    read -p "Group ID for mount ownership [$GROUP_ID]: " input_gid
    if [[ -n "$input_gid" ]]; then
        GROUP_ID="$input_gid"
    fi
    
    # Validate mount point path
    if [[ ! "$MOUNT_POINT" =~ ^/ ]]; then
        log_error "Mount point must be an absolute path (starting with /)"
        exit 1
    fi
    
    # Display configuration summary
    echo
    log_info "Configuration Summary:"
    echo "  SMB Share: //$SMB_HOST/$SMB_SHARE"
    echo "  Mount Point: $MOUNT_POINT"
    echo "  Username: $USERNAME"
    echo "  User ID: $USER_ID, Group ID: $GROUP_ID"
    echo "  Credentials File: $CREDENTIALS_FILE"
    echo
    
    read -p "Proceed with this configuration? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Configuration cancelled by user"
        exit 0
    fi
    
    log_info "Configuration accepted"
}
check_existing_mount() {
    if grep -q "$MOUNT_POINT" /etc/fstab; then
        log_warn "Mount point $MOUNT_POINT already exists in /etc/fstab"
        read -p "Do you want to continue and potentially create a duplicate entry? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting..."
            exit 0
        fi
    fi
}

# Install required packages
install_packages() {
    log_info "Installing cifs-utils..."
    if ! sudo apt update && sudo apt install cifs-utils -y; then
        log_error "Failed to install cifs-utils"
        exit 1
    fi
}

# Create mount point
create_mount_point() {
    log_info "Creating mount point: $MOUNT_POINT"
    if ! sudo mkdir -p "$MOUNT_POINT"; then
        log_error "Failed to create mount point: $MOUNT_POINT"
        exit 1
    fi
    
    # Set ownership to the user running the script
    local current_user=$(logname 2>/dev/null || echo $USER)
    if [[ -n "$current_user" && "$current_user" != "root" ]]; then
        sudo chown "$current_user:$current_user" "$MOUNT_POINT"
        log_info "Mount point ownership set to $current_user"
    fi
}

# Create credentials file
create_credentials() {
    log_info "Creating credentials file: $CREDENTIALS_FILE"
    
    # Create samba directory if it doesn't exist
    sudo mkdir -p "$(dirname "$CREDENTIALS_FILE")"
    
    # Create credentials file
    sudo tee "$CREDENTIALS_FILE" > /dev/null << EOF
username=$USERNAME
password=$PASSWORD
EOF
    
    # Secure the credentials file
    if ! sudo chmod 600 "$CREDENTIALS_FILE"; then
        log_error "Failed to set permissions on credentials file"
        exit 1
    fi
    
    log_info "Credentials file created and secured"
}

# Add entry to fstab
add_to_fstab() {
    log_info "Adding entry to /etc/fstab..."
    
    # Create backup of fstab
    sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
    log_info "Backup of /etc/fstab created"
    
    # Add mount entry
    echo "//$SMB_HOST/$SMB_SHARE $MOUNT_POINT cifs credentials=$CREDENTIALS_FILE,uid=$USER_ID,gid=$GROUP_ID,iocharset=utf8,file_mode=0777,dir_mode=0777,vers=3.0 0 0" | sudo tee -a /etc/fstab > /dev/null
    
    log_info "Entry added to /etc/fstab"
}

# Test the mount
test_mount() {
    log_info "Testing mount..."
    sudo systemctl daemon-reload
    
    if sudo mount -a; then
        log_info "Mount successful!"
        
        # Verify mount
        if mountpoint -q "$MOUNT_POINT"; then
            log_info "✓ $MOUNT_POINT is successfully mounted"
            
            # Show mount details
            df -h | grep "$MOUNT_POINT" || true
        else
            log_warn "Mount command succeeded but $MOUNT_POINT is not mounted"
        fi
    else
        log_error "Mount failed. Check your credentials and network connectivity"
        log_info "You can manually test with: sudo mount -t cifs //$SMB_HOST/$SMB_SHARE $MOUNT_POINT -o credentials=$CREDENTIALS_FILE"
        exit 1
    fi
}

# Cleanup function for error handling
cleanup() {
    if [[ $? -ne 0 ]]; then
        log_error "Script failed. You may need to manually clean up:"
        log_error "- Remove credentials file: sudo rm -f $CREDENTIALS_FILE"
        log_error "- Remove mount point: sudo rmdir $MOUNT_POINT 2>/dev/null"
        log_error "- Restore fstab backup if created"
    fi
}

# Main function
main() {
    log_info "Starting SMB auto-mount setup..."
    
    trap cleanup EXIT
    
    check_sudo
    prompt_configuration
    check_existing_mount
    install_packages
    create_mount_point
    create_credentials
    add_to_fstab
    test_mount
    
    log_info "✓ SMB auto-mount setup completed successfully!"
    log_info "The share will automatically mount on boot at: $MOUNT_POINT"
}

# Run main function
main "$@"