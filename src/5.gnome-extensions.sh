#!/bin/bash

# Script to automatically install GNOME extensions without user confirmation
# Author: Claude
# Date: April 8, 2025

set +e  # Exit on error
trap 'exit_code=$?; echo "Error on line $LINENO: exit code $exit_code"; exit $exit_code' ERR

# Terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if we're running GNOME
if ! gnome-shell --version &>/dev/null; then
    echo -e "${RED}ERROR: GNOME Shell not found. Are you running GNOME?${NC}"
    exit 1
fi

# Check for required tools
for cmd in wget unzip gnome-extensions; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}ERROR: Required command '$cmd' not found. Please install it first.${NC}"
        exit 1
    fi
done

# Get GNOME Shell version
GNOME_SHELL_VERSION=$(gnome-shell --version | cut -d' ' -f3)
echo -e "${BLUE}Detected GNOME Shell version: $GNOME_SHELL_VERSION${NC}"

# Get terminal width for progress bar
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
PROGRESS_WIDTH=$((TERM_WIDTH - 10))

# Display progress bar
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local completed=$((percent * PROGRESS_WIDTH / 100))
    local remaining=$((PROGRESS_WIDTH - completed))
    
    # Create the filled and empty portions of the progress bar
    local fill=$(printf "%${completed}s" | tr ' ' '#')
    local empty=$(printf "%${remaining}s" | tr ' ' '.')
    
    printf "\r[%s%s] %3d%%" "$fill" "$empty" "$percent"
}

# Get UUID of extension from URL or ID
get_extension_uuid() {
    local extension_id="$1"
    local uuid=""
    
    # If it looks like a URL, extract the ID
    if [[ "$extension_id" =~ ^https?://extensions.gnome.org ]]; then
        extension_id=$(echo "$extension_id" | grep -oP 'extensions.gnome.org/extension/\K\d+' || echo "$extension_id")
    fi

    # If it's numeric, fetch info from extensions site
    if [[ "$extension_id" =~ ^[0-9]+$ ]]; then
        local info_url="https://extensions.gnome.org/extension-info/?pk=$extension_id"
        local extension_info
        
        # Use wget to get extension info (silent mode)
        extension_info=$(wget -q -O- "$info_url" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            # Extract UUID
            uuid=$(echo "$extension_info" | yq -r '.uuid')
        fi
        
        if [[ -z "$uuid" ]]; then
            echo "Failed to get UUID for extension $extension_id" >&2
            return 1
        fi
    else
        # Assume it's already a UUID
        uuid="$extension_id"
    fi
    
    # Output UUID to stdout for capture
    echo "$uuid"
    return 0
}

# Download and install extension
install_extension() {
    local extension_id="$1"
    local uuid
    
    # Get UUID
    uuid=$(get_extension_uuid "$extension_id")
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to get UUID for extension $extension_id${NC}" >&2
        return 1
    fi

    # Check if already installed
    if gnome-extensions list | grep -q "$uuid"; then
        echo -e "\n${YELLOW}⚠ Extension $uuid already installed.${NC}"
        return 2  # Special return code for already installed
    fi
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Try to download from extensions.gnome.org
    local download_url="https://extensions.gnome.org/download-extension/$uuid.shell-extension.zip?shell_version=$GNOME_SHELL_VERSION"
    
    echo -e "${BLUE}Downloading from: $download_url${NC}" >&2
    
    # Download with error output
    if ! wget -q "$download_url" -O extension.zip 2>wget.error; then
        echo -e "${RED}Download failed. Error: $(cat wget.error)${NC}" >&2
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${BLUE}Installing extension: $uuid${NC}" >&2
    
    # Install with error output visible - use the ZIP file directly
    if ! gnome-extensions install --force "extension.zip" 2>install.error; then
        echo -e "${RED}Installation failed. Error: $(cat install.error)${NC}" >&2
        # Try to get more detailed error information
        echo -e "${YELLOW}Extension files:${NC}" >&2
        ls -la extension.zip >&2
        echo -e "${YELLOW}Extension contents:${NC}" >&2
        unzip -l extension.zip >&2
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Extension $uuid installed successfully${NC}" >&2
    return 0
}

# Enable an installed extension
enable_extension() {
    local uuid="$1"
    local installed_exts=$(gnome-extensions list)
    
    # First try exact match
    if ! echo "$installed_exts" | grep -q "^$uuid$"; then
        # If not found, try partial match
        local found_uuid=$(echo "$installed_exts" | grep -i "$uuid" | head -n1)
        if [[ -n "$found_uuid" ]]; then
            echo -e "${YELLOW}Using found extension UUID: $found_uuid${NC}" >&2
            uuid="$found_uuid"
        else
            echo -e "${RED}Extension $uuid not found in installed extensions${NC}" >&2
            echo -e "${YELLOW}Installed extensions:${NC}" >&2
            echo "$installed_exts" >&2
            return 1
        fi
    fi
    
    # Check extension info and status
    echo -e "${BLUE}Checking extension status...${NC}" >&2
    gnome-extensions info "$uuid" >&2
    
    # Try to enable the extension with error capture
    if ! gnome-extensions enable "$uuid" 2>enable.error; then
        echo -e "${RED}Failed to enable extension. Error: $(cat enable.error)${NC}" >&2
        echo -e "${YELLOW}Extension state: $(gnome-extensions show "$uuid" 2>/dev/null || echo 'unknown')${NC}" >&2
        # Check for common issues
        if grep -qi "not compatible" enable.error; then
            echo -e "${YELLOW}Extension appears to be incompatible with current GNOME version ($GNOME_SHELL_VERSION)${NC}" >&2
        fi
        return 1
    fi
    
    # Add delay to allow extension to be enabled
    sleep 1
    
    # Verify the extension was actually enabled
    if ! gnome-extensions list --enabled | grep -q "$uuid"; then
        echo -e "${RED}Extension not enabled after enable command${NC}" >&2
        echo -e "${YELLOW}This might require a GNOME Shell restart${NC}" >&2
        # Try to get more diagnostic information
        dbus-send --session --dest=org.gnome.Shell \
                  --type=method_call \
                  /org/gnome/Shell \
                  org.gnome.Shell.ExtensionStatus \
                  "string:$uuid" >/dev/null 2>&1
        return 1
    fi
    
    echo -e "${GREEN}Extension $uuid enabled successfully${NC}" >&2
    return 0
}

# Main function to process extensions
process_extensions() {
    local extensions_file="$1"
    local successful=()
    local failed=()
    local skipped=()
    local total=0
    local current=0
    
    # Check if the file exists
    if [[ ! -f "$extensions_file" ]]; then
        echo -e "${RED}ERROR: Extensions list file '$extensions_file' not found.${NC}"
        exit 1
    fi
    
    # Count total extensions first
    while read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        total=$((total + 1))
    done < "$extensions_file"
    
    echo -e "${BLUE}=== Starting Installation of $total GNOME Extensions ===${NC}"
    echo
    
    show_progress 0 $total
    
    # Read the file line by line again for actual processing
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        current=$((current + 1))
        show_progress $current $total
        
        # Prepare extension name/id for display
        local display_name="$line"
        if [[ ${#display_name} -gt 40 ]]; then
            display_name="${display_name:0:37}..."
        fi
        
        echo -e "\n\n${BLUE}[$current/$total] Processing: $display_name${NC}"
        
        # Install the extension
        install_extension "$line"
        local install_status=$?
        
        if [[ $install_status -eq 2 ]]; then
            # Already installed
            local uuid=$(get_extension_uuid "$line")
            skipped+=("$line|$uuid")
            continue
        elif [[ $install_status -eq 0 ]]; then
            # Try to enable it
            local uuid=$(get_extension_uuid "$line")
            if [[ $? -eq 0 ]] && enable_extension "$uuid"; then
                echo -e "${GREEN}✓ Extension successfully installed and enabled${NC}"
                successful+=("$line")
            else
                echo -e "${RED}✗ Extension installed but could not be enabled${NC}"
                failed+=("$line")
            fi
        else
            echo -e "${RED}✗ Failed to install extension${NC}"
            failed+=("$line")
        fi
    done < "$extensions_file"
    
    # Print final newline after progress bar
    echo -e "\n"
    
    # Generate detailed report
    echo -e "${BLUE}=== Installation Summary ===${NC}"
    echo -e "Total extensions processed: ${YELLOW}$total${NC}"
    echo -e "Successfully installed: ${GREEN}${#successful[@]}${NC}"
    echo -e "Failed: ${RED}${#failed[@]}${NC}"
    echo -e "Already installed: ${YELLOW}${#skipped[@]}${NC}"
    
    # Show successful extensions
    if [[ ${#successful[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}=== Successfully Installed Extensions ===${NC}"
        for ext in "${successful[@]}"; do
            uuid=$(get_extension_uuid "$ext")
            echo -e "${GREEN}✓ $ext ${NC}($uuid)"
        done
    fi
    
    # Show failed extensions
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo -e "\n${RED}=== Failed Extensions ===${NC}"
        for ext in "${failed[@]}"; do
            echo -e "${RED}✗ $ext${NC}"
        done
    fi
    
    # Show skipped extensions
    if [[ ${#skipped[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}=== Already Installed Extensions ===${NC}"
        for entry in "${skipped[@]}"; do
            IFS='|' read -r ext uuid <<< "$entry"
            echo -e "${YELLOW}⚠ $ext ${NC}($uuid)"
        done
    fi
    
    # Inform user they may need to restart GNOME Shell
    echo -e "\n${BLUE}NOTE: You may need to restart GNOME Shell for changes to take effect.${NC}"
    echo -e "${BLUE}Press Alt+F2, type 'r' and press Enter (in X11), or log out and back in (in Wayland).${NC}"
}

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 EXTENSIONS_FILE"
    echo ""
    echo "EXTENSIONS_FILE: A text file containing a list of GNOME extensions to install."
    echo "                 Each line should contain either:"
    echo "                 - An extension ID number"
    echo "                 - A full URL to the extension on extensions.gnome.org"
    echo "                 - A UUID of an extension"
    echo ""
    echo "Example file content:"
    echo "# My favorite extensions"
    echo "307  # Dash to Dock"
    echo "https://extensions.gnome.org/extension/3628/arcmenu/"
    echo "user-theme@gnome-shell-extensions.gcampax.github.com"
    exit 1
fi

# Process the extensions file
process_extensions "$1"

# Finish
echo -e "\n${GREEN}Script completed.${NC}"
exit 0