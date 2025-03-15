# Example Ansible Project for Cisco IOS XE 17.x Configuration

This repository provides a **basic example** of how to use Ansible to automate the configuration of Cisco IOS XE devices running version 17.x. It demonstrates simple configuration tasks and IOS upgrades.

**IMPORTANT:** This project is an *example only* and is **NOT SUITABLE FOR PRODUCTION USE** in its current state. It lacks crucial security features, most importantly the implementation of Ansible Vault for secure credential management. See the "Improvements Needed" section below for a list of critical changes required before using this in a production environment.  **DO NOT USE THIS PROJECT WITH REAL DEVICES WITHOUT FIRST IMPLEMENTING ANSIBLE VAULT AND OTHER SECURITY IMPROVEMENTS.**

## Features (Demonstrated in this Example)

*   **Basic IOS XE Configuration:**
    *   Hostname
    *   Domain Name
    *   Users and Passwords (**INSECURE: Passwords are initially entered in plain text, but MUST be encrypted with Ansible Vault immediately!**)
    *   SSH Configuration (**INSECURE: Lacks access control lists!**)
*   **IOS XE Upgrade (Basic Example):**
    *   Image transfer via TFTP
    *   Software installation

## Requirements

*   **Ansible:** Version 2.9 or later (tested with 2.10+). Newer versions are strongly recommended.
*   **Python:** Version 3.6 or later.
*   **Ansible Collections:**
    *   `cisco.ios` (already specified in `requirements.yml`)
*   **Cisco IOS XE Devices:** Version 17.x.
*   **Network Connectivity:** Your Ansible control node must have network connectivity to the managed Cisco devices.
* **TFTP Server:** Required for IOS upgrades. You need a TFTP server accessible from your Cisco devices.
* **SSH Client:** You'll need an SSH client on your Ansible control node (usually comes pre-installed on Linux/macOS).

## Installation (Example Only - Not for Production)

1.  **Install Ansible:**

    ```bash
    pip install ansible
    ```

2.  **Install Required Collections:**

    ```bash
    ansible-galaxy collection install -r requirements.yml
    ```

3.  **Clone this Repository:**

    ```bash
    git clone https://github.com/cherrywheel/Example-Ansible-Cisco-IX-17.git
    cd Example-Ansible-Cisco-IX-17
    ```

4.  **Generate SSH Keys (Recommended):**

    *   While not *strictly* required for this basic example (which initially uses password authentication), it's *highly recommended* to use SSH keys for secure access to your devices. This is *essential* for production.

    *   On your Ansible control node, generate an SSH key pair (if you don't already have one):

        ```bash
        ssh-keygen -t ed25519 -C "your_email@example.com"
        ```
        (You can use `rsa` instead of `ed25519` if your devices don't support Ed25519 keys: `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`)

        *   Press Enter to accept the default file location (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`).
        *   Enter a strong passphrase (recommended) or leave it blank (less secure).

    *   Copy the *public* key (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`) to your Cisco device. You can do this manually (using copy and paste) or with `ssh-copy-id` (if available):

        ```bash
        # Manual method (replace with your device IP and username)
        # 1.  Connect to your device via SSH (using a password for now):
        #     ssh your_username@your_device_ip
        # 2.  Enter enable mode:
        #     enable
        # 3.  Enter configuration mode:
        #     configure terminal
        # 4.  Create a user (if one doesn't exist):
        #     username your_username privilege 15 secret your_password
        # 5.  Enter the public key (replace with the contents of your .pub file):
        #     ip ssh pubkey-chain
        #       username your_username
        #         key-string
        #           <PASTE YOUR PUBLIC KEY HERE>
        #         exit
        #       exit
        #     exit
        # 6.  Save the configuration:
        #     write memory


        # ssh-copy-id method (if available - replace with your device IP and username)
        ssh-copy-id your_username@your_device_ip
        ```

        *   **Important:** After configuring SSH key authentication, you should *disable password authentication* on your Cisco devices for increased security (this is *not* covered in this basic example).

## Configuration (Example Only - Requires Ansible Vault for Security)

1.  **Inventory (`hosts.ini`):**

    *   Modify the `hosts.ini` file to include the IP addresses or hostnames of your Cisco devices.  Specify `ansible_network_os=ios` for IOS devices.

        ```ini
        [ios]
        sw1  ansible_host=172.16.1.81
        ```

2.  **Group Variables (`group_vars/all.yml` - *REQUIRES ANSIBLE VAULT*):**

    *   **CRITICAL:** You *must* use Ansible Vault to encrypt sensitive data (passwords) in this file.  The steps below show how to do this.  **DO NOT SKIP THESE STEPS.**

    *   Create a plain text file named `vault_password.txt` in the project's root directory.  This file will contain *only* your chosen strong vault password.  **Do not commit this file to your Git repository!** Add it to a `.gitignore` file.
    *   Edit the `group_vars/all.yml` file. Enter your desired values for the variables, but **do not save the file with plain text passwords yet.**

    * **Encrypt the sensitive variables *immediately* using `ansible-vault encrypt_string`:**

        ```bash
        # Encrypt the ansible_password
        ansible-vault encrypt_string 'your_actual_ansible_password' --name 'ansible_password' --vault-password-file vault_password.txt

        # Copy the ENTIRE output and replace the plain text password in group_vars/all.yml
        # It will look something like this:
        # ansible_password: !vault |
        #   $ANSIBLE_VAULT;1.1;AES256
        #   6a346536303762393765353434343434663338653866353637613034373766313831366136383266
        #   ... (rest of the encrypted string)

        # Repeat for ansible_become_pass:
        ansible-vault encrypt_string 'your_actual_enable_password' --name 'ansible_become_pass' --vault-password-file vault_password.txt

        # Copy and paste the ENTIRE output, replacing the plain text value.
        ```

    *  **After encrypting the variables**, save the `group_vars/all.yml` file.  It should now contain *only* encrypted passwords.
    * You can edit encrypted file using:
     ```bash
        ansible-vault edit group_vars/all.yml --vault-password-file vault_password.txt
     ```

3.  **Ansible Configuration (`ansible.cfg`):**

    *   The `ansible.cfg` file includes some basic settings.  Review and adjust as needed. *Note that `host_key_checking = False` is for testing only and should be enabled in production.*

## Usage (Example Only - Requires Ansible Vault for Security)

1.  **Dry Run (Check Mode):**

    *   *Always* run your playbook in check mode first to see what changes would be made *without* actually applying them.  Since you're now using Ansible Vault, you *must* provide the vault password:

        ```bash
        ansible-playbook -i hosts.ini site.yml --check --vault-password-file vault_password.txt
        ```
        Or, to be prompted for the password:
        ```
        ansible-playbook -i hosts.ini site.yml --check -k
        ```

2.  **Show Differences (Diff Mode):**

    ```bash
    ansible-playbook -i hosts.ini site.yml --check --diff --vault-password-file vault_password.txt
    ```

3.  **Apply the Configuration (AFTER Implementing Ansible Vault):**

    ```bash
    ansible-playbook -i hosts.ini site.yml --vault-password-file vault_password.txt
    ```
    Or:
    ```bash
        ansible-playbook -i hosts.ini site.yml -k
    ```

## Directory Structure
cisco-automation/          # Main project directory (you can name it anything)
├── ansible.cfg           # Ansible configuration file: sets global Ansible behavior
├── inventory/            # Directory containing inventory files
│   ├── hosts             # Main inventory file: lists your Cisco devices (INI or YAML format)
│   └── group_vars/       # Directory containing group variable files
│       └── cisco_devices.yml  # Variables for the 'cisco_devices' group (USE ANSIBLE VAULT!)
│   └── host_vars/        # Directory containing host specific variables
│       └── cisco1.yml    # Example of host specific variables
├── playbooks/            # Directory containing Ansible playbooks
│   └── cisco_config.yml  # Main playbook: defines the tasks to run on your devices
├── roles/                # Directory containing Ansible roles
│   ├── base_config/      # Role for basic Cisco IOS XE configuration
│   │   ├── tasks/        # Directory containing the role's tasks
│   │   │   └── main.yml  # Main task file for the base_config role
│   │   ├── vars/         # Directory containing variables specific to the role
│   │   │   └── main.yml  # Variables that should NOT be easily overridden
│   │   └── defaults/     # Directory containing default variable values for the role
│   │       └── main.yml  # Default variables (easily overridden by group_vars or host_vars)
│   └── wireguard_config/ # Role for WireGuard configuration (if you're using WireGuard)
│       ├── tasks/
│       │   └── main.yml
│       ├── vars/
│       │   └── main.yml
│       └── defaults/
│           └── main.yml
├── .gitignore            # File specifying files/folders to be ignored by Git
├── README.md             # Project documentation file
├── requirements.yml      # Specifies Ansible collection dependencies
└── LICENSE # Specifies Ansible collection dependencies


## Improvements Needed (Before Production Use)

This project is a **basic example** and requires *significant* improvements before it can be considered production-ready:

*   **Refactor Group Variables:** Use `group_vars/cisco_devices.yml` (or similar) instead of `group_vars/all.yml`. This improves organization and avoids potential variable conflicts.
*   **Add `host_vars` Support:** Implement `host_vars` for host-specific configurations (e.g., different IP addresses, hostnames).
*   **Improve `ansible.cfg`:** Add more robust settings (timeouts, etc.).
*   **Enhance SSH Configuration:** Implement access control lists (ACLs) to restrict SSH access. This is a critical security measure. Also, disable password authentication after setting up SSH keys.
*   **Improve IOS Upgrade:**
    *   Use `cisco.ios.ios_install` instead of `copy` and raw commands for a more robust and reliable upgrade process.
    *   Add checks to verify if an upgrade is actually needed before proceeding.
*   **Complete Roles:** Add `vars/main.yml` and `defaults/main.yml` to the roles for better organization and flexibility.
*   **Add a License File:** Specify a license (e.g., MIT) for the project.
*   **Create a `.gitignore` File:** Prevent sensitive files (like `vault_password.txt`) and temporary files from being accidentally committed to the repository.
*   **Add More Comprehensive Error Handling:** Implement better error handling and reporting throughout the playbook and roles.
*   **Add More Comments:** Improve code readability with more comments.

## Troubleshooting

*   **Connectivity Issues:** Ensure that your Ansible control node can reach the Cisco devices via SSH. Verify IP addresses, hostnames, and network connectivity.
*   **Authentication Errors:** Double-check your usernames and passwords. **Ensure you are using Ansible Vault correctly to manage encrypted credentials.** If using SSH keys, ensure the public key is correctly installed on the device.
*   **IOS XE Version Compatibility:** Verify that your IOS XE version is supported.
*   **Ansible Errors:** Pay close attention to the error messages provided by Ansible. Increase verbosity with `-v`, `-vv`, or `-vvv` for more detailed output.
* **TFTP server errors:** Check that TFTP server is accessible and the IOS image presented on it.

## Contributing

Feel free to contribute!

## License

To be determined.
