# Requires: Run as Administrator

Write-Host "`n=== OpenSSH Server Setup Script for Windows Server 2022 ===" -ForegroundColor Cyan

# Step 1: Install OpenSSH Server and Client if not already installed
function Ensure-OpenSSHInstalled {
    $client = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
    $server = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

    if ($client.State -ne 'Installed') {
        Write-Host "Installing OpenSSH Client..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name 'OpenSSH.Client~~~~0.0.1.0'
    } else {
        Write-Host "OpenSSH Client is already installed." -ForegroundColor Green
    }

    if ($server.State -ne 'Installed') {
        Write-Host "Installing OpenSSH Server..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
    } else {
        Write-Host "OpenSSH Server is already installed." -ForegroundColor Green
    }
}

# Step 2: Enable and start sshd service
function Ensure-SSHDServiceRunning {
    Write-Host "`nConfiguring sshd service..." -ForegroundColor Cyan

    Set-Service -Name 'sshd' -StartupType 'Automatic'
    Start-Service -Name 'sshd'

    $svc = Get-Service sshd
    if ($svc.Status -eq 'Running') {
        Write-Host "sshd service is running." -ForegroundColor Green
    } else {
        Write-Error "sshd service failed to start!"
        exit 1
    }
}

# Step 3: Configure sshd_config for password and certificate-based login
function Configure-SSHDConfig {
    $configPath = "$env:ProgramData\ssh\sshd_config"

    Write-Host "`nUpdating sshd_config..." -ForegroundColor Cyan

    $config = Get-Content $configPath

    $updated = $config `
        | ForEach-Object {
            $_ `
            -replace '^\s*#?\s*PasswordAuthentication\s+.*', 'PasswordAuthentication yes' `
            -replace '^\s*#?\s*PubkeyAuthentication\s+.*', 'PubkeyAuthentication yes' `
            -replace '^\s*#?\s*AuthorizedKeysFile\s+.*', 'AuthorizedKeysFile .ssh/authorized_keys'
        }

    # Append TrustedUserCAKeys if not present
    if ($updated -notmatch 'TrustedUserCAKeys') {
        $updated += "`nTrustedUserCAKeys C:\ProgramData\ssh\trusted_ca_keys"
    }

    # Save updated config
    $updated | Set-Content $configPath

    # Restart service
    Restart-Service sshd
}

# Step 4: Confirm SSH is listening
function Confirm-SSHDListening {
    Write-Host "`nChecking if SSH is listening on port 22..." -ForegroundColor Cyan
    $isListening = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
    if ($isListening) {
        Write-Host "✅ SSH is listening on port 22." -ForegroundColor Green
    } else {
        Write-Error "❌ SSH is NOT listening on port 22."
        exit 1
    }
}

# Step 5: Configure Firewall
function Configure-FirewallRule {
    $existingRule = Get-NetFirewallRule -DisplayName "OpenSSH Server (sshd)" -ErrorAction SilentlyContinue
    if (-not $existingRule) {
        Write-Host "Adding firewall rule to allow SSH (TCP 22)..." -ForegroundColor Yellow
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Host "Firewall rule for SSH already exists." -ForegroundColor Green
    }
}

# Step 6: Test local SSH connectivity
function Test-SSHLocalhost {
    Write-Host "`nTesting SSH connection to localhost..." -ForegroundColor Cyan
    try {
        $output = ssh localhost whoami
        if ($output -match 'administrator') {
            Write-Host "✅ SSH to localhost succeeded as $output" -ForegroundColor Green
        } else {
            Write-Warning "SSH connection succeeded, but returned unexpected output: $output"
        }
    } catch {
        Write-Error "❌ SSH to localhost failed. Check if user is allowed and password is correct."
        exit 1
    }
}

# Execute all steps
Ensure-OpenSSHInstalled
Ensure-SSHDServiceRunning
Configure-SSHDConfig
Configure-FirewallRule
Confirm-SSHDListening
Test-SSHLocalhost

Write-Host "`n✅ OpenSSH setup complete. Password and certificate authentication should now work." -ForegroundColor Cyan