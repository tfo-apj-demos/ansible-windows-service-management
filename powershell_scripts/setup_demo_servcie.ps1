# ===============================
# Setup: Mock Windows Service using existing AD service account
# ===============================

# Configuration
$ServiceName     = "DemoHelloWorldService"
$ScriptPath      = "C:\demo-service\hello.ps1"
$NSSMDir         = "C:\nssm"
$NSSMPath        = "$NSSMDir\nssm.exe"
$LogPath         = "C:\demo-service\demo-service.log"
$ServiceAccount  = "hashicorp.local\svc-demo"   # Existing AD service account
$ServicePassword = "P@ssword123!"               # Initial password (rotate later in Vault/AAP)

# Step 0: Ensure NSSM is available
function Ensure-NSSM {
    if (-Not (Test-Path $NSSMPath)) {
        Write-Host "NSSM not found. Downloading..." -ForegroundColor Yellow
        $nssmZipUrl = "https://nssm.cc/release/nssm-2.24.zip"
        $nssmZip = "$env:TEMP\nssm.zip"
        $extractPath = "$env:TEMP\nssm-extracted"

        Invoke-WebRequest -Uri $nssmZipUrl -OutFile $nssmZip
        Expand-Archive -Path $nssmZip -DestinationPath $extractPath -Force

        # Find correct arch (use win64 if present, else fallback)
        if (Test-Path "$extractPath\nssm-2.24\win64\nssm.exe") {
            New-Item -ItemType Directory -Force -Path $NSSMDir | Out-Null
            Copy-Item "$extractPath\nssm-2.24\win64\nssm.exe" -Destination $NSSMPath
        } elseif (Test-Path "$extractPath\nssm-2.24\win32\nssm.exe") {
            New-Item -ItemType Directory -Force -Path $NSSMDir | Out-Null
            Copy-Item "$extractPath\nssm-2.24\win32\nssm.exe" -Destination $NSSMPath
        } else {
            Write-Error "❌ Unable to locate nssm.exe in extracted archive."
            exit 1
        }

        Write-Host "✅ NSSM installed to $NSSMPath" -ForegroundColor Green
    } else {
        Write-Host "✅ NSSM already available at $NSSMPath" -ForegroundColor Green
    }
}

# Step 1: Create the service script
function Create-DemoScript {
    Write-Host "Creating demo script..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path "C:\demo-service" | Out-Null

    @'
while ($true) {
    "Hello World - $(Get-Date)" | Out-File -Append "C:\demo-service\demo-service.log"
    Start-Sleep -Seconds 10
}
'@ | Set-Content -Path $ScriptPath -Encoding UTF8
}

# Step 2: Install the service with NSSM
function Install-MockService {
    Write-Host "Installing service '$ServiceName' using NSSM..." -ForegroundColor Cyan
    & $NSSMPath install $ServiceName "powershell.exe" "-ExecutionPolicy Bypass -File `"$ScriptPath`""
}

# Step 3: Set service to run as the AD service account
function Configure-ServiceAccount {
    Write-Host "Configuring service to run as '$ServiceAccount'..." -ForegroundColor Cyan
    & $NSSMPath set $ServiceName ObjectName "$ServiceAccount" "$ServicePassword"
}

# Step 4: Start and configure the service
function Start-MockService {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    Write-Host "`n✅ Service '$ServiceName' is running under '$ServiceAccount'." -ForegroundColor Green
}

# Run all steps
Ensure-NSSM
Create-DemoScript
Install-MockService
Configure-ServiceAccount
Start-MockService