# Ansible Windows Service Management

This repository contains Ansible playbooks and roles for managing Windows services, specifically for rotating service account passwords using HashiCorp Vault integration with Ansible Automation Platform 2.5.

## Repository Structure

```
ansible-windows-service-management/
├── ansible.cfg                    # Ansible configuration
├── requirements.yml               # Ansible collections and roles
├── inventory/                     # Inventory files
│   ├── group_vars/               # Group variables
│   ├── host_vars/                # Host-specific variables
│   └── hosts.yml                 # Main inventory
├── playbooks/                    # Main playbooks
│   ├── rotate-service-passwords.yml
│   ├── manage-windows-services.yml
│   └── site.yml
├── roles/                        # Custom roles
│   ├── windows_service_management/
│   └── vault_credential_rotation/
├── collections/                  # Local collections (if any)
├── filter_plugins/              # Custom filters
├── vars/                        # Variable files
└── templates/                   # Jinja2 templates
```

## Prerequisites

- Ansible Automation Platform 2.5
- Windows hosts with WinRM configured
- HashiCorp Vault with LDAP secrets engine
- Proper network connectivity between AAP and Windows hosts

## Quick Start

1. Configure your inventory in `inventory/hosts.yml`
2. Set up group variables in `inventory/group_vars/windows_servers.yml`
3. Configure Vault credentials in AAP
4. Run the service password rotation playbook

## Usage

### Rotate Service Account Passwords

```bash
ansible-playbook playbooks/rotate-service-passwords.yml -i inventory/hosts.yml
```

### Manage Windows Services

```bash
ansible-playbook playbooks/manage-windows-services.yml -i inventory/hosts.yml
```

## Configuration

See the `inventory/group_vars/` directory for configuration options.

## Security

This repository handles sensitive credentials. Ensure proper access controls and use Ansible Vault for sensitive data.