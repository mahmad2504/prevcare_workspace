# PowerShell script to setup and run PrevCare Fullstack development environment
# Run this script from the workspace root directory
#
# ============================================================================
# USAGE EXAMPLES (Recommended: Use the batch file to avoid execution policy issues)
# ============================================================================
#
# Using the batch file (RECOMMENDED):
#   setup-dev-environment.bat                          # Run all steps
#   setup-dev-environment.bat backend                   # Run only backend
#   setup-dev-environment.bat mysql                     # Run only MySQL Docker
#   setup-dev-environment.bat frontend                  # Run only frontend
#   setup-dev-environment.bat transcriber               # Run only transcriber
#   setup-dev-environment.bat transcriber-new          # Run only transcriber-new
#   setup-dev-environment.bat checkout                 # Run only code checkout
#   setup-dev-environment.bat backend,frontend          # Run backend and frontend
#   setup-dev-environment.bat mysql,backend,transcriber # Run multiple steps
#
# Using PowerShell directly (requires execution policy bypass):
#   .\setup-dev-environment.ps1                        # Run all steps
#   .\setup-dev-environment.ps1 -Step backend          # Run only backend
#   .\setup-dev-environment.ps1 -Step mysql             # Run only MySQL Docker
#   .\setup-dev-environment.ps1 -Step frontend          # Run only frontend
#   .\setup-dev-environment.ps1 -Step transcriber       # Run only transcriber
#   .\setup-dev-environment.ps1 -Step transcriber-new  # Run only transcriber-new
#   .\setup-dev-environment.ps1 -Step checkout         # Run only code checkout
#   .\setup-dev-environment.ps1 -Step backend,frontend  # Run multiple steps
#
# ============================================================================
# AVAILABLE STEPS
# ============================================================================
#   checkout        - Step 1: Code checkout from Azure DevOps repository
#   mysql           - Step 2: Setup and run MySQL Docker container
#   backend         - Step 3: Setup and run Backend service (yarn)
#   frontend        - Step 4: Setup and run Frontend service (yarn)
#   transcriber     - Step 5: Setup and run Audio Transcriber service (yarn)
#   transcriber-new - Step 6: Setup and run Audio Transcriber Backend-New (npm)
#
# ============================================================================
# WHAT EACH STEP DOES
# ============================================================================
# Step 1 (checkout):
#   - Clones or updates the repository from Azure DevOps
#   - Checks out the branch: new-transcriber-component-integration
#
# Step 2 (mysql):
#   - Copies docker-compose.yml from C:\ZWORK\Notes\Run-healthcare-software
#   - Starts MySQL Docker container in detached mode
#
# Step 3 (backend):
#   - Copies .env (backend) and env.conf (backend) to backend directory
#   - Opens new console window
#   - Runs: npm install -g yarn, yarn install, yarn prisma:generate, yarn prisma:reset, yarn start:dev
#
# Step 4 (frontend):
#   - Opens new console window
#   - Runs: yarn install, yarn start
#
# Step 5 (transcriber):
#   - Copies .env (transcriber) to audio-transcriber/backend directory
#   - Opens new console window
#   - Runs: yarn install, yarn start:dev
#
# Step 6 (transcriber-new):
#   - Copies .env (backend-new) to audio-transcriber/backend-new directory
#   - Opens new console window
#   - Runs: npm install, npm start
#
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Step = "all"
)

$ErrorActionPreference = "Continue"

# Define step mappings
$StepMap = @{
    "checkout" = 1
    "mysql" = 2
    "backend" = 3
    "frontend" = 4
    "transcriber" = 5
    "transcriber-new" = 6
}

# Parse step parameter
$StepsToRun = @()
if ($Step -eq "all") {
    $StepsToRun = @(1,2,3,4,5,6)
} else {
    $StepNames = $Step -split ',' | ForEach-Object { $_.Trim().ToLower() }
    foreach ($stepName in $StepNames) {
        if ($StepMap.ContainsKey($stepName)) {
            $StepsToRun += $StepMap[$stepName]
        } else {
            Write-Host "[ERROR] Unknown step: $stepName" -ForegroundColor Red
            Write-Host "Available steps: $($StepMap.Keys -join ', ')" -ForegroundColor Yellow
            exit 1
        }
    }
    $StepsToRun = $StepsToRun | Sort-Object -Unique
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PrevCare Fullstack Dev Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($Step -ne "all") {
    $SelectedSteps = $StepsToRun | ForEach-Object { 
        ($StepMap.GetEnumerator() | Where-Object { $_.Value -eq $_ }).Key 
    }
    Write-Host "Running steps: $($SelectedSteps -join ', ')" -ForegroundColor Cyan
}
Write-Host ""

# Configuration
$RepoUrl = "https://dev.azure.com/fnawaz/CHI%20Development/_git/prevcare-fullstack"
$BranchName = "new-transcriber-component-integration"
$RepoDir = "prevcare-fullstack"
$NotesDir = "C:\ZWORK\Notes\Run-healthcare-software"

# Get the workspace root directory
if ($PSScriptRoot) {
    $WorkspaceRoot = $PSScriptRoot
} else {
    $WorkspaceRoot = Get-Location
}
Set-Location $WorkspaceRoot

# Step 1: Code Checkout
if ($StepsToRun -contains 1) {
    Write-Host "[1/6] Code Checkout..." -ForegroundColor Yellow
    if (Test-Path $RepoDir) {
    Write-Host "Repository directory exists. Checking out branch..." -ForegroundColor Gray
    Set-Location $RepoDir
    git fetch origin
    git checkout -b $BranchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Branch might already exist, switching to it..." -ForegroundColor Gray
        git checkout $BranchName
    }
    Set-Location $WorkspaceRoot
} else {
    Write-Host "Cloning repository..." -ForegroundColor Gray
    git clone $RepoUrl $RepoDir -b $BranchName
    Set-Location $WorkspaceRoot
    }
    Write-Host "[OK] Code checkout completed" -ForegroundColor Green
    Write-Host ""
}

# Step 2: Run MySQL Docker
if ($StepsToRun -contains 2) {
    Write-Host "[2/6] Setting up MySQL Docker..." -ForegroundColor Yellow
    $DockerComposeSource = Join-Path $NotesDir "docker-compose.yml"
    $DockerComposeDest = Join-Path $WorkspaceRoot "docker-compose_mysql.yml"
    
    if (Test-Path $DockerComposeSource) {
        Copy-Item $DockerComposeSource $DockerComposeDest -Force
        Write-Host "Copied docker-compose.yml to docker-compose_mysql.yml" -ForegroundColor Gray
        Write-Host "Starting MySQL Docker container..." -ForegroundColor Gray
        docker-compose -f docker-compose_mysql.yml up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] MySQL Docker container started" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to start MySQL Docker container" -ForegroundColor Red
        }
    } else {
        Write-Host "[ERROR] docker-compose.yml not found at $DockerComposeSource" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 3: Run Backend
if ($StepsToRun -contains 3) {
    Write-Host "[3/6] Setting up Backend..." -ForegroundColor Yellow
    $BackendDir = Join-Path (Join-Path $WorkspaceRoot $RepoDir) "backend"
    if (Test-Path $BackendDir) {
        Write-Host "Backend directory: $BackendDir" -ForegroundColor Gray
        Write-Host "Source directory: $NotesDir" -ForegroundColor Gray
        
        # Check if source directory exists
        if (-not (Test-Path $NotesDir)) {
            Write-Host "[ERROR] Source directory not found: $NotesDir" -ForegroundColor Red
        } else {
            Write-Host "Listing files in source directory..." -ForegroundColor Gray
            Get-ChildItem -Path $NotesDir -File | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor DarkGray }
        }
        
        $BackendEnvSource = Join-Path $NotesDir ".env (backend)"
        $BackendEnvDest = Join-Path $BackendDir ".env"
        $BackendConfSource = Join-Path $NotesDir "env.conf (backend)"
        $BackendConfDest = Join-Path $BackendDir "env.conf"
        
        Write-Host "Looking for .env (backend) at: $BackendEnvSource" -ForegroundColor Gray
        if (Test-Path -LiteralPath $BackendEnvSource) {
            Copy-Item -LiteralPath $BackendEnvSource -Destination $BackendEnvDest -Force
            Write-Host "[OK] Copied .env file to backend" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] .env (backend) not found at $BackendEnvSource" -ForegroundColor Yellow
        }
        
        Write-Host "Looking for env.conf (backend) at: $BackendConfSource" -ForegroundColor Gray
        if (Test-Path -LiteralPath $BackendConfSource) {
            Write-Host "[FOUND] File exists at source" -ForegroundColor Green
            try {
                # Ensure destination directory exists
                if (-not (Test-Path $BackendDir)) {
                    New-Item -ItemType Directory -Path $BackendDir -Force | Out-Null
                }
                
                # Copy the file
                Copy-Item -LiteralPath $BackendConfSource -Destination $BackendConfDest -Force -ErrorAction Stop
                Write-Host "Copy command executed" -ForegroundColor Gray
                
                # Verify the copy
                Start-Sleep -Milliseconds 500
                if (Test-Path -LiteralPath $BackendConfDest) {
                    $SourceSize = (Get-Item -LiteralPath $BackendConfSource).Length
                    $DestSize = (Get-Item -LiteralPath $BackendConfDest).Length
                    if ($SourceSize -eq $DestSize) {
                        Write-Host "[OK] Copied env.conf file to backend (verified: $DestSize bytes)" -ForegroundColor Green
                    } else {
                        Write-Host "[WARNING] File copied but size mismatch. Source: $SourceSize bytes, Dest: $DestSize bytes" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "[ERROR] Copy command executed but file not found at destination: $BackendConfDest" -ForegroundColor Red
                }
            } catch {
                Write-Host "[ERROR] Failed to copy env.conf: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Source: $BackendConfSource" -ForegroundColor Red
                Write-Host "Destination: $BackendConfDest" -ForegroundColor Red
            }
        } else {
            Write-Host "[ERROR] env.conf (backend) not found at: $BackendConfSource" -ForegroundColor Red
            Write-Host "Please verify the file exists at the source location." -ForegroundColor Yellow
        }
        
        Write-Host "Opening new window for Backend..." -ForegroundColor Gray
        $BackendScript = @"
@echo off
cd /d "$BackendDir"
call npm install -g yarn
call yarn install
call yarn prisma:generate
call yarn prisma:reset
call yarn start:dev
pause
"@
        $BackendScriptPath = Join-Path $env:TEMP "start-backend.bat"
        $BackendScript | Out-File -FilePath $BackendScriptPath -Encoding ASCII
        Start-Process cmd.exe -ArgumentList "/k", $BackendScriptPath
        Write-Host "[OK] Backend setup initiated in new window" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Backend directory not found at $BackendDir" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 4: Run Frontend
if ($StepsToRun -contains 4) {
    Write-Host "[4/6] Setting up Frontend..." -ForegroundColor Yellow
    $FrontendDir = Join-Path (Join-Path $WorkspaceRoot $RepoDir) "frontend"
    # Check if it exists relative to repo or absolute path
    if (-not (Test-Path $FrontendDir)) {
        $FrontendDir = "C:\WORK\prevcare-fullstack\frontend"
        if (-not (Test-Path $FrontendDir)) {
            $FrontendDir = Join-Path (Join-Path $WorkspaceRoot $RepoDir) "frontend"
        }
    }
    
    if (Test-Path $FrontendDir) {
        Write-Host "Opening new window for Frontend..." -ForegroundColor Gray
        $FrontendScript = @"
@echo off
cd /d "$FrontendDir"
call yarn install && call yarn start
pause
"@
        $FrontendScriptPath = Join-Path $env:TEMP "start-frontend.bat"
        $FrontendScript | Out-File -FilePath $FrontendScriptPath -Encoding ASCII
        Start-Process cmd.exe -ArgumentList "/k", $FrontendScriptPath
        Write-Host "[OK] Frontend setup initiated in new window" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Frontend directory not found at $FrontendDir" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 5: Run Audio Transcriber
if ($StepsToRun -contains 5) {
    Write-Host "[5/6] Setting up Audio Transcriber..." -ForegroundColor Yellow
    $TranscriberDir = Join-Path (Join-Path $WorkspaceRoot $RepoDir) "audio-transcriber\backend"
    if (Test-Path $TranscriberDir) {
        $TranscriberEnvSource = Join-Path $NotesDir ".env (transcriber)"
        $TranscriberEnvDest = Join-Path $TranscriberDir ".env"
        
        if (Test-Path -LiteralPath $TranscriberEnvSource) {
            Copy-Item -LiteralPath $TranscriberEnvSource -Destination $TranscriberEnvDest -Force
            Write-Host "Copied .env file to audio-transcriber/backend" -ForegroundColor Gray
        } else {
            Write-Host "[WARNING] .env (transcriber) not found at $TranscriberEnvSource" -ForegroundColor Yellow
        }
        
        Write-Host "Opening new window for Audio Transcriber..." -ForegroundColor Gray
        $TranscriberScript = @"
@echo off
cd /d "$TranscriberDir"
call yarn install && call yarn start:dev
pause
"@
        $TranscriberScriptPath = Join-Path $env:TEMP "start-transcriber.bat"
        $TranscriberScript | Out-File -FilePath $TranscriberScriptPath -Encoding ASCII
        Start-Process cmd.exe -ArgumentList "/k", $TranscriberScriptPath
        Write-Host "[OK] Audio Transcriber setup initiated in new window" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Audio Transcriber directory not found at $TranscriberDir" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 6: Run Audio Transcriber Backend-New
if ($StepsToRun -contains 6) {
    Write-Host "[6/6] Setting up Audio Transcriber Backend-New..." -ForegroundColor Yellow
    $TranscriberBackendNewDir = Join-Path (Join-Path $WorkspaceRoot $RepoDir) "audio-transcriber\backend-new"
    if (Test-Path $TranscriberBackendNewDir) {
        $TranscriberBackendNewEnvSource = Join-Path $NotesDir ".env (backend-new)"
        $TranscriberBackendNewEnvDest = Join-Path $TranscriberBackendNewDir ".env"
        
        Write-Host "Looking for .env (backend-new) at: $TranscriberBackendNewEnvSource" -ForegroundColor Gray
        if (Test-Path -LiteralPath $TranscriberBackendNewEnvSource) {
            try {
                Copy-Item -LiteralPath $TranscriberBackendNewEnvSource -Destination $TranscriberBackendNewEnvDest -Force -ErrorAction Stop
                if (Test-Path -LiteralPath $TranscriberBackendNewEnvDest) {
                    Write-Host "[OK] Copied .env file to audio-transcriber/backend-new" -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Copy command executed but file not found at destination" -ForegroundColor Red
                }
            } catch {
                Write-Host "[ERROR] Failed to copy .env: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "[WARNING] .env (backend-new) not found at $TranscriberBackendNewEnvSource" -ForegroundColor Yellow
        }
        
        Write-Host "Opening new window for Audio Transcriber Backend-New..." -ForegroundColor Gray
        $TranscriberBackendNewScript = @"
@echo off
cd /d "$TranscriberBackendNewDir"
call npm install
if %ERRORLEVEL% EQU 0 (
    call npm start
) else (
    echo npm install failed, not starting the service
)
pause
"@
        $TranscriberBackendNewScriptPath = Join-Path $env:TEMP "start-transcriber-backend-new.bat"
        $TranscriberBackendNewScript | Out-File -FilePath $TranscriberBackendNewScriptPath -Encoding ASCII
        Start-Process cmd.exe -ArgumentList "/k", $TranscriberBackendNewScriptPath
        Write-Host "[OK] Audio Transcriber Backend-New setup initiated in new window" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Audio Transcriber Backend-New directory not found at $TranscriberBackendNewDir" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All services are starting in separate command windows." -ForegroundColor Gray
Write-Host "Please wait for each service to fully start before using the application." -ForegroundColor Gray
Write-Host ""

