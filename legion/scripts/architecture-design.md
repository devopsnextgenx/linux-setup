# Architecture Design: Modular Shell Script Framework

## Overview
This document outlines the design patterns and architectural principles used to refactor monolithic shell scripts into a modular, maintainable framework. The primary goal is to move away from "God Scripts" toward a structured, domain-driven architecture.

Use appropriate Skill linux-script-writer for writing scripts.

## Core Components

### Folder Structure
- All Scripts are stored in `scripts/` folder
- All dependencies should be stored in `scripts/modules` or `scripts/modules/<submodules>`
- Before writing scripts to `submodule`, verify `scripts/modules/module-design.md` to see any of existing module can be reused.
- If any module is reusable, make sure its moved from `scripts/modules/<submodules>` to `scripts/modules`
- Always document any refactor/creation of modules/submodules scripts in `scripts/modules/module-design.md`

### 1. The Orchestrator
The entry point of the system. It does not perform the work itself but manages the lifecycle of the entire process.
- **Command Routing**: Parses global flags (`--uninstall`, `--dry-run`, `--verify`, `--force`).
- **Execution Sequencing**: Defines the strict order in which modules must be executed to satisfy dependencies.
- **Error Management**: Acts as the supervisor, capturing failures from sub-modules to provide a high-level summary.
- **Simulation Mode**: Implements `--dry-run` by intercepting module calls and logging intended actions without execution.

### 2. Module Layer (`modules/**/*.sh`)
Independent, single-purpose scripts that handle one logical domain, organized into submodules.
- **Submodules**: Modules are grouped under subdirectories named after their parent orchestrator script (e.g., `modules/shared-setup/` or `modules/osx-setup/`).
- **Shared Modules**: Modules used by multiple scripts or other modules remain in the base `modules/` directory.
- **Domain Isolation**: Each module focuses on a single concern (e.g., `shared-setup/01-users.sh` handles identity, `osx-setup/04-wallpapers.sh` handles visuals).
- **Self-Sufficiency**: Modules are designed to be executable standalone for testing and debugging.
- **Lifecycle Contract**: Every module implements a standard interface:
    - **Setup**: The primary logic to achieve the target state.
    - **Uninstall**: The inverse logic to revert changes.

### 3. Shared Layer (`modules/config.sh` & `modules/utils.sh`)
The foundation that ensures consistency across all components.
- **`config.sh` (The Source of Truth)**: Centralizes all constants (paths, versions, user lists, package names). This allows system-wide updates (e.g., upgrading a Go version) by changing a single line.
- **`utils.sh` (The UI/UX Engine)**: Provides standardized colorized logging (Info, Success, Warn, Error), progress spinners, and common logic (e.g., root privilege checks).

---

## Refactoring Pattern: Monolith $\to$ Modules

When refactoring a large script, follow this five-phase approach:

### Phase 1: Domain Analysis
1.  **Identify Boundaries**: Read the monolith and group lines into logical stages (e.g., Package Installation $\to$ Environment Config $\to$ User Setup).
2.  **Identify Constants**: Locate all hardcoded paths, versions, and strings that define the system's identity.

### Phase 2: Establishing the Foundation
1.  **Build `utils.sh`**: Define the visual and functional "language" of the system (colors, logging functions).
2.  **Build `config.sh`**: Move all identified constants into this file. **Crucial:** Replace all hardcoded values in your monolith with variables from `config.sh`.

### Phase 3: Iterative Module Extraction
For every logical domain identified in Phase 1:
1.  **Isolate**: Create a new script in a submodule directory (e.g., `modules/my-submodule/XX-domain.sh`).
2.  **Inject**: Source `utils.sh` and `config.sh` at the start of the script.
3.  **Implement Lifecycle**:
    *   Write the `setup_domain()` function.
    *   Write the `uninstall_domain()` function (the inverse logic).
4.  **Enforce Idempotency**: Ensure the module can be run multiple times without side effects (e.g., check if a user exists before `usermod`).

### Phase 4: Orchestration Construction
1.  **Create the Orchestrator**: Build the main entry point that calls modules in order.
2.  **Implement Global Logic**:
    *   **Orchestrated Uninstall**: Call modules in **reverse order** of their setup.
    *   **Simulation**: Implement `--dry-run` by wrapping module calls in a conditional that logs instead of executing.
    *   **Verification**: Implement a `--verify` flag that performs sanity checks (e.g., "Does this directory exist?", "Is this group present?").

## Core Principles for Maintainability

| Principle | Description |
| :--- | :--- |
| **Single Responsibility** | A module should do one thing. If it handles both `apt` and `flatpak`, split it. |
| **Idempotency** | Scripts must be "run-ready." Running them twice should result in the same state as running once. |
| **Fail-Fast** | Use `set -euo pipefail` to ensure errors stop execution immediately. |
| **No Side Effects in Config** | `config.sh` must only define data; it should never execute system commands. |
| **Interface Consistency** | All modules must respect the same flag/behavior pattern to allow the Orchestrator to control them. |
