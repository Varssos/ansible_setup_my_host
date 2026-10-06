---
name: ansible-add-platform
description: >
  Skill for adding a new Linux distribution to the ansible_setup_my_host project.
  Covers all files that must be updated: Vagrantfile, run.sh, hosts, README.md,
  run_status.md. Also covers how to temporarily disable a platform.
  Project root: ~/Documents/my_files/ansible/ansible_setup_my_host
---

# ansible-add-platform

## Overview

Adding a new platform requires updating **5 files** in sync. Missing any of them
will cause either Vagrant or Ansible to fail silently or skip the platform.

---

## Port assignment convention

Ports are assigned by OS family to avoid collisions with existing VMs:

| OS family    | Port range | Examples                        |
|--------------|------------|---------------------------------|
| Ubuntu       | 2000–2999  | 2204, 2404, 2504, 2604          |
| Linux Mint   | 3000–3999  | 3220 (wilma), 3222 (zara), 3223 (zena) |
| Debian       | 4100–4999  | 4131                            |
| Other        | 5000+      | free to assign                  |

The port number should encode the OS version where possible
(e.g., Ubuntu 26.04 → port 2604, Debian 13.1 → port 4131).

---

## Currently supported platforms (active)

| Name              | Box                          | SSH port | Notes                    |
|-------------------|------------------------------|----------|--------------------------|
| `ubuntu2204`      | `bento/ubuntu-22.04`         | 2204     | LTS                      |
| `ubuntu2404`      | `bento/ubuntu-24.04`         | 2404     | LTS (LATEST_UBUNTU_LTS)  |
| `linuxmint223zena`| `mgldvd/linuxmint-22.3-zena` | 3223     | (LATEST_LINUX_MINT)      |
| `debian131`       | `bento/debian-13.1`          | 4131     | (LATEST_DEBIAN)          |

## Currently disabled platforms (commented out)

| Name                | Reason                                    |
|---------------------|-------------------------------------------|
| `ubuntu2504`        | Temporarily not supported                 |
| `linuxmint222zara`  | Superseded by 22.3 zena                   |
| `linuxmint22wilma`  | Issues with sudo apt update on start      |

---

## Step 1 – Find a Vagrant box

Search on https://app.vagrantup.com/boxes/search for the distro.
Preferred providers (in order): `bento/*`, then distro-specific publishers.

Examples:
```
bento/ubuntu-26.04
bento/debian-14
mgldvd/linuxmint-23.0-<codename>
```

Verify the box exists and has a VirtualBox provider before proceeding.

---

## Step 2 – Update Vagrantfile

File: `vagrant_for_ansible/Vagrantfile`

Add a new entry to the `boxes` hash. Follow the existing pattern exactly —
including the blank line between entries:

```ruby
  boxes = {
    # ... existing entries ...
    "ubuntu2404" => {
      box: "bento/ubuntu-24.04",
      host_port: 2404
    },
    # ↓ ADD NEW ENTRY HERE (alphabetical order within OS family)
    "ubuntu2604" => {
      box: "bento/ubuntu-26.04",
      host_port: 2604
    },
    "linuxmint223zena" => {
```

The provisioning shell script (useradd, SSH config, etc.) is shared — no need
to modify it for new platforms.

---

## Step 3 – Update run.sh

File: `vagrant_for_ansible/run.sh`

Three things to update:

### 3a. Add to ALL_VERSIONS

```bash
# Before:
ALL_VERSIONS=("ubuntu2204" "ubuntu2404" "linuxmint223zena" "debian131")

# After (example: adding ubuntu2604):
ALL_VERSIONS=("ubuntu2204" "ubuntu2404" "ubuntu2604" "linuxmint223zena" "debian131")
```

### 3b. Update LATEST_* variable if this is now the newest in its family

```bash
LATEST_UBUNTU_LTS_VERSION="ubuntu2604"   # was ubuntu2404
LATEST_LINUX_MINT_VERSION="linuxmint230"  # example
LATEST_DEBIAN_VERSION="debian14"          # example
```

### 3c. Add a named flag if desired (optional, for convenience)

```bash
# In the case "$arg" section:
mint)
    VERSIONS=("$LATEST_LINUX_MINT_VERSION")
    ;;
```

---

## Step 4 – Update hosts

File: `hosts`

Add a new line in the correct OS section inside the `[docker]` group.
The SSH port must match `host_port` in Vagrantfile.

```ini
[docker]
# Ubuntu
ubuntu2204 ansible_host=localhost ansible_user=test_user ansible_connection=ssh ansible_ssh_port=2204 ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
ubuntu2404 ansible_host=localhost ansible_user=test_user ansible_connection=ssh ansible_ssh_port=2404 ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
# ↓ ADD NEW LINE (same pattern, change name and port only)
ubuntu2604 ansible_host=localhost ansible_user=test_user ansible_connection=ssh ansible_ssh_port=2604 ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
```

The `ansible_ssh_common_args` value is always identical for all Vagrant VMs —
copy it verbatim.

---

## Step 5 – Update README.md

File: `README.md`

Add the new platform to the "Supported platforms" section:

```markdown
Supported platforms:
- Ubuntu:
    - 22.04
    - 24.04
    - 26.04    ← add
- Mint:
    - Zara 22.2
    - Zena 22.3
```

---

## Step 6 – Update run_status.md

File: `run_status.md`

Add a new section for the platform with status "not yet tested":

```markdown
## Ubuntu 26.04
⏳ Not yet tested
```

After the first successful test run, update to:

```markdown
## Ubuntu 26.04
✅ OK - <date>
```

---

## Step 7 – Test the new platform

Run only the new platform first to save time:

```bash
cd vagrant_for_ansible
./run.sh clean all 2>&1 | tee /tmp/ansible_run.log
```

Or if you added a named flag:

```bash
./run.sh clean ubuntu 2>&1 | tee /tmp/ansible_run.log
```

Check for failures and fix using the `ansible-vagrant-test-fix-loop` skill.

---

## Disabling a platform (temporary)

To comment out a platform without deleting it, update all 3 runtime files:

### Vagrantfile
```ruby
# "ubuntu2504" => {
#   box: "bento/ubuntu-25.04",
#   host_port: 2504
# },
```

### run.sh — remove from ALL_VERSIONS, keep as comment
```bash
ALL_VERSIONS=("ubuntu2204" "ubuntu2404" "linuxmint223zena" "debian131") # ubuntu2504 currently not supported
```

### hosts — comment out the line
```ini
# ubuntu2504 ansible_host=localhost ansible_user=test_user ansible_connection=ssh ansible_ssh_port=2504 ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
```

Update `run_status.md` with reason:
```markdown
## Ubuntu 25.04
⚠️ Skipped (commented out) — <reason>
```

---

## Checklist

```
[ ] Vagrantfile    — new entry in boxes hash with correct box name and host_port
[ ] run.sh         — added to ALL_VERSIONS, updated LATEST_* if newest in family
[ ] hosts          — new line in [docker] group with matching port
[ ] README.md      — added to "Supported platforms" list
[ ] run_status.md  — new section added
[ ] Tested         — ./run.sh all ran successfully, run_status.md updated to ✅
```
