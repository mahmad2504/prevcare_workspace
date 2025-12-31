# ============================================================================
# Configuration file for setup-dev-environment.ps1
# ============================================================================
# Edit this file to customize the setup script behavior without modifying
# the main script file.
#
# This file should be placed in the same directory as setup-dev-environment.ps1
# ============================================================================

# Azure DevOps Repository Configuration
# Repository URL to clone from Azure DevOps
$RepoUrl = "https://dev.azure.com/fnawaz/CHI%20Development/_git/prevcare-fullstack"

# Branch name to checkout after cloning
$BranchName = "new-transcriber-component-integration"

# Directory Configuration
# Local directory name where the repository will be cloned
$RepoDir = "prevcare-fullstack"

# Directory containing configuration files (.env, env.conf, docker-compose.yml)
# This is where the script looks for files like:
#   - .env (backend)
#   - env.conf (backend)
#   - .env (transcriber)
#   - .env (backend-new)
#   - docker-compose.yml
$NotesDir = "C:\ZWORK\Notes\Run-healthcare-software"

