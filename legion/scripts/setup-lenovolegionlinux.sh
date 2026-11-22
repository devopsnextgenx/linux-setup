#!/usr/bin/env bash
set -euo pipefail

# Load configuration and utilities
# Assuming this script is in scripts/ and modules/ is in scripts/modules/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/modules/config.sh" ]] && source "$SCRIPT_DIR/modules/config.sh"
[[ -f "$SCRIPT_DIR/modules/utils.sh" ]] && source "$SCRIPT_DIR/modules/utils.sh"

# Module directory
MODULE_DIR="$SCRIPT_DIR/modules/legion-setup"

# Flags
DRY_RUN=false
FORCE=false
UNINSTALL=false
VERIFY=false

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Description: $LEGION_DESCRIPTION"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  -v, --version           Show the version information and exit"
    echo "  --uninstall             Uninstall the installed components"
    echo "  --dry-run               Show what would be done without making changes"
    echo "  --verify                Verify the current installation status"
    echo "  --force                 Skip confirmation prompts and overwrite existing files"
    echo ""
    echo "Modules sequence:"
    echo "  1. Dependencies"
    echo "  2. Source Code"
    echo "  3. Kernel Module"
    echo "  4. Python Environment"
    echo "  5. System Integration"
}

show_version() {
    echo "$LEGION_DESCRIPTION version $LEGION_VERSION"
}

ask_confirmation() {
    local prompt="$1"
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    local response
    read -r -p "$(echo -e "${YELLOW}[CONFIRM]${NC} $prompt (y/N): ")" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

run_module() {
    local module_script="$1"
    local module_name="$2"
    local action="$3" # setup_domain or uninstall_domain

    info "Executing $module_name: $action..."
    
    # Export flags so modules can see them
    export DRY_RUN="$DRY_RUN"
    export FORCE="$FORCE"
    
    # Call the module script
    # We use bash directly to ensure environment is passed
    bash "$module_script" "$action" || {
        error "Module $module_name failed during $action"
        exit 1
    }
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verify)
                VERIFY=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "$UNINSTALL" == "true" ]]; then
        if ! ask_confirmation "Are you sure you want to uninstall all components?"; then
            info "Uninstall cancelled."
            exit 0
        fi
        
        # Modules in reverse order for uninstall
        run_module "$MODULE_DIR/05-integration.sh" "Integration" "uninstall_domain"
        run_module "$MODULE_DIR/04-python.sh" "Python" "uninstall_domain"
        run_module "$MODULE_DIR/03-kernel.sh" "Kernel" "uninstall_domain"
        run_module "$MODULE_DIR/02-source.sh" "Source" "uninstall_domain"
        run_module "$MODULE_DIR/01-dependencies.sh" "Dependencies" "uninstall_domain"
        
        success "Uninstall complete."

    elif [[ "$VERIFY" == "true" ]]; then
        # Verification doesn't need to be a module, or it can be one.
        # Using the module we created.
        source "$MODULE_DIR/06-verify.sh"
        verify_installation || exit 1

    else
        info "Starting Installation: $LEGION_DESCRIPTION"
        
        run_module "$MODULE_DIR/01-dependencies.sh" "Dependencies" "setup_domain"
        run_module "$MODULE_DIR/02-source.sh" "Source" "setup_domain"
        run_module "$MODULE_DIR/03-kernel.sh" "Kernel" "setup_domain"
        run_module "$MODULE_DIR/04-python.sh" "Python" "setup_domain"
        run_module "$MODULE_DIR/05-integration.sh" "Integration" "setup_domain"
        
        info "Installation complete. Please run --verify to ensure everything is correct."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
