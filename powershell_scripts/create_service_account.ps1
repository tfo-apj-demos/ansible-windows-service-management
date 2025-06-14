# Import the AD module
Import-Module ActiveDirectory

# Parameters — adjust as needed
$SamAccountName = "svc-demo"
$DisplayName    = "Vault Managed Service Account - Demo"
$OU             = "OU=Vault Managed Accounts,DC=hashicorp,DC=local"
$Password       = ConvertTo-SecureString "P@ssword123!" -AsPlainText -Force
$UPN            = "$SamAccountName@hashicorp.local"

# Create the AD user
New-ADUser `
    -Name $SamAccountName `
    -SamAccountName $SamAccountName `
    -UserPrincipalName $UPN `
    -DisplayName $DisplayName `
    -Path $OU `
    -AccountPassword $Password `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Description "Service Account for Vault-managed Windows Service demo"

# Confirm
Write-Host "✅ Service account '$SamAccountName' created in OU='$OU'." -ForegroundColor Green