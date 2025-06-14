# Ansible Windows Service Management

This repository contains Ansible playbooks and roles for managing Windows services via SSH using OpenSSH for Windows and PowerShell. Designed for use with Ansible Automation Platform (AAP) 2.5.

## Repository Structure

```
ansible-windows-service-management/
├── ansible.cfg                    # Ansible configuration
├── collections/
│   └── requirements.yml           # Ansible collections
├── inventory/                     # Sample inventory
│   └── hosts                     # Sample inventory file
├── playbooks/                    # Main playbooks
│   ├── test-connectivity.yml     # SSH connectivity test
│   ├── manage-services.yml       # Windows service management
│   ├── rotate-passwords.yml      # Vault password rotation (multi-play role-based)
│   ├── requirements.yml          # Playbook collections
│   └── roles/                    # Custom roles following AAP best practices
│       ├── windows_service_status/          # Get current service status
│       │   ├── tasks/main.yml
│       │   └── vars/main.yml
│       ├── vault_credential_retrieval/      # Vault AppRole auth & credential retrieval
│       │   ├── tasks/main.yml
│       │   └── vars/main.yml
│       └── windows_service_credential_update/  # Update service credentials via NSSM
│           ├── tasks/main.yml
│           └── vars/main.yml
└── aap-host-variables-example.yml # Example AAP host variables
```

## Design Pattern

This repository follows Ansible best practices with a **multi-play, role-based structure** similar to proven patterns:

1. **Play 1**: Target Windows hosts to get current service status
   - Role: `windows_service_status`
   - Connection: SSH to Windows hosts

2. **Play 2**: Target localhost (execution environment) for Vault operations
   - Role: `vault_credential_retrieval`
   - Connection: Local (no SSH)
   - Purpose: AppRole authentication and credential retrieval

3. **Play 3**: Target Windows hosts to update credentials and restart services
   - Role: `windows_service_credential_update`
   - Connection: SSH to Windows hosts
   - Variables: Passed from Play 2 via `hostvars['localhost']`

This pattern ensures Vault operations run locally in the execution environment while Windows operations use SSH, avoiding connection issues and following AAP security best practices.

## Prerequisites

- Ansible Automation Platform 2.5
- Windows hosts with OpenSSH Server installed and configured
- PowerShell 5.1+ on Windows hosts
- Proper network connectivity between AAP and Windows hosts (port 22)
- AAP Machine Credentials configured for SSH authentication

## Windows OpenSSH Setup

Ensure OpenSSH is installed and configured on your Windows servers. This can be done through Group Policy, PowerShell DSC, or manually on each server:

**PowerShell commands for manual setup:**
```powershell
# Install OpenSSH Server (Windows 10/Server 2019+)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure PowerShell as default shell for SSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

## AAP Configuration

### Machine Credentials
1. Create a **Machine Credential** in AAP:
   - **Credential Type**: Machine
   - **Username**: Your Windows user (domain\user or user@domain.com)
   - **Password**: User's password
   - **Privilege Escalation**: Not typically needed for Windows SSH

### Job Templates
Create job templates with these settings:
- **Playbook**: `playbooks/test-ssh-connection.yml` (for testing)
- **Playbook**: `playbooks/manage-windows-services-ssh.yml` (for service management)
- **Inventory**: Your Windows inventory
- **Credentials**: Your Machine credential
- **Extra Variables**: As needed (see examples below)

## Quick Start

1. **Test Connectivity**: Run the test playbook first
   - Job Template: "Test Windows SSH Connection"
   - Playbook: `playbooks/test-ssh-connection.yml`
   - Extra Variables: `target_hosts: your_host_or_group`

2. **Manage Services**: Use the service management playbook
   - Job Template: "Windows Service Management"
   - Playbook: `playbooks/manage-windows-services-ssh.yml`

## Usage Examples

### Test Basic Connectivity
```yaml
# No extra variables needed - targets windows_servers group directly
```

### Check Service Status
```yaml
# Extra Variables:
service_operation: "status"
services_list: ["MSSQLSERVER", "SQLSERVERAGENT"]
```

### Start Services
```yaml
# Extra Variables:
service_operation: "start"
services_list: ["MSSQLSERVER", "SQLSERVERAGENT"]
```

### Stop Services
```yaml
# Extra Variables:
service_operation: "stop"
services_list: ["IIS", "W3SVC"]
```

### Restart Services
```yaml
# Extra Variables:
service_operation: "restart"
services_list: ["Spooler", "Themes"]
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify OpenSSH is installed and running on Windows
   - Check firewall allows port 22
   - Verify AAP can reach the Windows host

2. **PowerShell Errors**
   - Ensure PowerShell is set as default SSH shell
   - Check PowerShell execution policy
   - Verify user has appropriate permissions

3. **Service Management Errors**
   - Ensure user has permission to manage services
   - Check if services exist on target system
   - Verify service names are correct (case-sensitive)

### Testing Commands

Test SSH connectivity from AAP by running the test playbook:
- Use the "Test Windows SSH Connection" job template
- Check job output for connectivity confirmation

## Playbook Reference

| Playbook | Purpose | Key Variables | Structure |
|----------|---------|---------------|-----------|
| `test-connectivity.yml` | Basic SSH connectivity test | None required | Single play |
| `manage-services.yml` | Windows service management | `service_operation`, `services_list` | Single play |
| `rotate-passwords.yml` | Vault password rotation | `vault_url`, `role_id`, `secret_id`, `dependent_services` | **Multi-play role-based** |

### Role Breakdown

| Role | Purpose | Target | Connection |
|------|---------|--------|------------|
| `windows_service_status` | Get current service status | Windows hosts | SSH |
| `vault_credential_retrieval` | Vault AppRole auth & get credentials | localhost (EE) | local |
| `windows_service_credential_update` | Update service credentials via NSSM | Windows hosts | SSH |

## AAP Job Template Examples

### Test SSH Connectivity
- **Name**: Test Windows SSH Connection
- **Job Type**: Run
- **Inventory**: Your Windows Inventory
- **Project**: This repository
- **Playbook**: `playbooks/test-connectivity.yml`
- **Credentials**: Your Windows Machine Credential
- **Extra Variables**: None needed

### Manage Windows Services
- **Name**: Windows Service Management
- **Job Type**: Run
- **Inventory**: Your Windows Inventory
- **Project**: This repository
- **Playbook**: `playbooks/manage-services.yml`
- **Credentials**: Your Windows Machine Credential
- **Variables on Prompt**: Enable to allow runtime service selection
- **Extra Variables**:
  ```yaml
  service_operation: "status"  # status, start, stop, restart
  services_list: ["DemoHelloWorldService"]  # Optional - defaults to DemoHelloWorldService
  ```

### Rotate Service Passwords
- **Name**: Rotate Service Account Passwords
- **Job Type**: Run
- **Inventory**: Your Windows Inventory
- **Project**: This repository
- **Playbook**: `playbooks/rotate-passwords.yml`
- **Credentials**: Your Windows Machine Credential + Vault Credential (AppRole)
- **Extra Variables**:
  ```yaml
  vault_url: "https://vault.hashicorp.local:8200"
  vault_ldap_mount_path: "ldap"  # Your Vault LDAP mount path
  vault_static_role_name: "svc_demo"  # Your Vault LDAP static role
  dependent_services: ["DemoHelloWorldService"]  # Services to update/restart
  role_id: "{{ vault_role_id }}"  # From Vault credential
  secret_id: "{{ vault_secret_id }}"  # From Vault credential
  ```

## Vault Integration

This playbook integrates with your Vault LDAP static role configuration:

```hcl
resource "vault_ldap_secret_backend_static_role" "svc_demo" {
  mount           = vault_ldap_secret_backend.this.path
  role_name       = "svc_demo"
  username        = "svc-demo"
  dn              = "CN=svc-demo,OU=Vault Managed Accounts,DC=hashicorp,DC=local"
  rotation_period = 300  # 5 minutes
}
```

### Required AAP Credentials

1. **Machine Credential** (for Windows SSH):
   - Username: `HASHICORP\Administrator`
   - Password: Your Windows admin password

2. **Vault Credential** (Custom credential type for AppRole):
   - `role_id`: Your Vault AppRole role ID
   - `secret_id`: Your Vault AppRole secret ID

```bash
ansible-playbook playbooks/manage-windows-services.yml -i inventory/hosts.yml
```

## Configuration

See the `inventory/group_vars/` directory for configuration options.

## Security

This repository handles sensitive credentials. Ensure proper access controls and use Ansible Vault for sensitive data.