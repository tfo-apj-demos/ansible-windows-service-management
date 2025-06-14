# Ansible Windows Service Management

This repository contains Ansible playbooks and roles for managing Windows services via SSH using OpenSSH for Windows and PowerShell. Designed for use with Ansible Automation Platform (AAP) 2.5.

## Repository Structure

```
ansible-windows-service-management/
├── ansible.cfg                    # Ansible configuration
├── collections/
│   └── requirements.yml           # Ansible collections
├── inventory/                     # Inventory files
│   └── hosts                     # Sample inventory
├── playbooks/                    # Main playbooks
│   ├── test-ssh-connection.yml   # Basic connectivity test
│   ├── manage-windows-services-ssh.yml  # SSH-based service management
│   ├── rotate-service-passwords.yml     # Vault credential rotation
│   ├── requirements.yml          # Playbook collections
│   └── roles/                    # Custom roles
│       ├── windows_service_management/
│       └── vault_credential_rotation/
└── .vault_password               # Demo vault password (dev only)
```

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

| Playbook | Purpose | Key Variables |
|----------|---------|---------------|
| `test-ssh-connection.yml` | Basic connectivity test | `target_hosts` |
| `manage-windows-services-ssh.yml` | Service management | `service_operation`, `services_list` |
| `rotate-service-passwords.yml` | Vault password rotation | Vault configuration |

## AAP Job Template Examples

### Basic Connectivity Test
- **Name**: Test Windows SSH Connection
- **Job Type**: Run
- **Inventory**: Your Windows Inventory
- **Project**: This repository
- **Playbook**: `playbooks/test-ssh-connection.yml`
- **Credentials**: Your Windows Machine Credential
- **Extra Variables**: None needed (targets windows_servers group)

### Service Management
- **Name**: Windows Service Management
- **Job Type**: Run
- **Inventory**: Your Windows Inventory
- **Project**: This repository
- **Playbook**: `playbooks/manage-windows-services-ssh.yml`
- **Credentials**: Your Windows Machine Credential
- **Variables on Prompt**: Enable to allow runtime service selection

```bash
ansible-playbook playbooks/manage-windows-services.yml -i inventory/hosts.yml
```

## Configuration

See the `inventory/group_vars/` directory for configuration options.

## Security

This repository handles sensitive credentials. Ensure proper access controls and use Ansible Vault for sensitive data.