---
name: ansible-vagrant-test-fix-loop
description: >
  Skill for iterative test-and-fix of the ansible_setup_my_host project.
  Runs ./run.sh (with vagrant VMs), analyses Ansible and Vagrant failures
  from the output, automatically applies fixes to the correct files, and
  repeats until all platforms pass. Project root:
  ~/Documents/my_files/ansible/ansible_setup_my_host
---

# ansible-vagrant-test-fix-loop

## Overview

This skill drives a fully automated loop:

```
run ./run.sh  →  capture output  →  classify failures  →  fix files  →  repeat
```

Stop condition: `./run.sh` exits with code 0 **and** the playbook output contains
no `FAILED` or `fatal:` lines.

---

## Step 1 – Run the tests

Default: test only on the latest Linux Mint (fastest, defined in `run.sh` as
`LATEST_LINUX_MINT_VERSION`).

**For the test-fix loop always use `all` to catch OS-specific issues:**

```bash
cd ~/Documents/my_files/ansible/ansible_setup_my_host/vagrant_for_ansible
./run.sh all 2>&1 | tee /tmp/ansible_run.log
echo "EXIT: $?"
```

To limit to one platform (faster iteration during a specific fix):

```bash
./run.sh ubuntu 2>&1 | tee /tmp/ansible_run.log   # only ubuntu2404
./run.sh debian 2>&1 | tee /tmp/ansible_run.log   # only debian131
```

Destroy old VMs first (use when a previous run left a dirty VM state):

```bash
./run.sh clean all 2>&1 | tee /tmp/ansible_run.log
# or just for one platform:
./run.sh clean ubuntu 2>&1 | tee /tmp/ansible_run.log
```

Supported platform flags: `ubuntu` | `debian` | `all`
(no flag = latest Linux Mint only)

---

## Step 2 – Classify failures

### 2a. Ansible task failures

Look for these patterns in `/tmp/ansible_run.log`:

```
FAILED! => {...}
fatal: [<host>]: FAILED! => {"msg": "..."}
```

Extract:
- **host** – which VM failed (`ubuntu2204`, `ubuntu2404`, `linuxmint223zena`, `debian131`)
- **task name** – the line above `FAILED!` starting with `TASK [`
- **msg** – content of `"msg":` inside the JSON block

Map task name → file using `tasks/main.yml`:

| Task file              | Condition in main.yml                                      |
|------------------------|------------------------------------------------------------|
| `tasks/essential.yml`  | always runs (no `when:`)                                   |
| `tasks/chrome.yml`     | `when: 'google-chrome-stable' not in ansible_facts.packages` |
| `tasks/coolercontrol.yml` | `when: 'coolercontrol' not in ansible_facts.packages`   |
| `tasks/fzf.yml`        | `when: 'fzf' not in ansible_facts.packages`               |
| `tasks/grub-customizer.yml` | `when: 'grub-customizer' not in ansible_facts.packages` |
| `tasks/klogg.yml`      | `when: 'klogg' not in ansible_facts.packages`             |
| `tasks/nomachine.yml`  | `when: 'nomachine' not in ansible_facts.packages`         |
| `tasks/sublime.yml`    | `when: 'sublime-text' not in ansible_facts.packages`      |
| `tasks/virtualbox.yml` | `when: 'virtualbox-7.1' not in ansible_facts.packages`    |
| `tasks/vscode.yml`     | `when: 'code' not in ansible_facts.packages`              |
| `tasks/wireshark.yml`  | `when: 'wireshark' not in ansible_facts.packages`         |
| `tasks/signal.yml`     | `when: 'signal-desktop' not in ansible_facts.packages`    |
| `tasks/spotify.yml`    | `when: 'spotify-client' not in ansible_facts.packages`    |
| `tasks/xdotool.yml`    | always runs (no `when:`)                                   |

### 2b. Vagrant provisioning failures

```
Failed to start VM for <name>
```

Check VirtualBox/network errors in the lines before. Common cause: VM already running
→ use `./run.sh clean ...`.

### 2c. Ansible connection failures

```
UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}
```

The VM started but SSH is not ready. Wait or rebuild VM with `clean` option.

---

## Step 3 – Failure patterns and fixes

### Pattern A: Package not available on specific OS

**Log signal:**
```
No package matching '<name>' is available
```
or
```
Unable to locate package <name>
```

**Fix strategy:**

1. Identify which OS(es) it fails on.
2. If it fails only on **some** OS versions → move from `apt_packages` to
   `apt_packages_known_issues` in `group_vars/all/vars.yml`:

```yaml
# group_vars/all/vars.yml
apt_packages_known_issues:
  - anki          # Not available on Ubuntu 25.04
  - rpi-imager    # Not available on Debian 13.1
  - <new_package> # Not available on <OS version>
```

3. If it fails on **all** OS versions → the package name changed or the repo is
   missing. Fix the task file directly.

4. Update `run_status.md` with the known issue.

### Pattern B: GPG key download failure

**Log signal:**
```
Failed to download <url>
```
or
```
HTTP Error 404
```

**Fix strategy:**

Check the URL in the relevant task file (e.g., `tasks/signal.yml`, `tasks/vscode.yml`,
`tasks/klogg.yml`). Update the URL to the current one from the project's official
install docs. Pattern in these files:

```yaml
- name: Download <App> GPG key
  get_url:
    url: https://...   # ← update this URL
    dest: /tmp/...
```

### Pattern C: APT repository codename not supported

**Log signal:**
```
E: The repository 'https://... <codename> Release' does not have a Release file
```

**Fix strategy:**

The task hardcodes a codename (common in `tasks/klogg.yml`):

```yaml
# tasks/klogg.yml – uses hardcoded 'jammy' because newer codenames not yet supported
repo: "deb [arch=amd64 signed-by=...] https://... jammy jammy utils"
```

Options (in order of preference):
1. If newer codename is now supported by upstream → replace hardcoded codename with
   `{{ ubuntu_codename }}` (the fact set by `tasks/set_ubuntu_codename.yml`).
2. If not yet supported → keep hardcoded to latest working codename.
3. Add `ignore_errors: yes` with a comment explaining why.

### Pattern D: .deb download returns wrong content (404 page as HTML)

**Log signal:**
```
dpkg-deb: error: '<file>.deb' is not a Debian format archive
```

**Fix strategy:**

The URL in the task returns HTML instead of a real .deb. Add a verification step or
update the URL. Affected task files: `tasks/nomachine.yml`, `tasks/chrome.yml`.

In `tasks/nomachine.yml`, `nomachine_deb_url` is defined in `group_vars/all/vars.yml`:

```yaml
nomachine_deb_url: "https://www.nomachine.com/free/linux/64/deb"
```

Update this variable with the direct versioned URL from the NoMachine download page.

### Pattern E: systemd not available in Vagrant VM

**Log signal:**
```
System has not been booted with systemd as init system (PID 1)
```

**Fix strategy:**

Add `ignore_errors: yes` to the `systemctl` / `systemd` task with a comment:

```yaml
- name: Enable and start <service>
  systemd:
    name: <service>
    enabled: yes
    state: started
  ignore_errors: yes  # systemd not available in Vagrant/Docker test environments
```

### Pattern F: fzf key-bindings path not found (Debian)

**Log signal:**
```
the field 'path' should be a string but was None/empty
```

**Fix strategy in `tasks/fzf.yml`:**

The `find` command returns empty on Debian because the path differs.
Add a fallback:

```yaml
- name: Setup fzf key bindings
  lineinfile:
    path: /home/{{ ansible_user }}/.bashrc
    line: "source {{ key_bindings_path.stdout }}"
    state: present
    create: yes
  when: key_bindings_path.stdout | length > 0
```

### Pattern G: Vagrant VM fails to start (VirtualBox error)

**Log signal:**
```
There was an error while executing `VBoxManage`
```
or
```
Failed to start VM for <name>
```

**Fix strategy:**

1. Try with `clean` flag first to destroy stale VMs.
2. Check VirtualBox is running: `systemctl status virtualbox`
3. Check no leftover VMs in VirtualBox: `VBoxManage list vms`
4. Remove orphaned VMs: `VBoxManage unregistervm "<name>" --delete`

### Pattern H: SSH timeout during `vagrant up` ("Timed out while waiting for the machine to boot")

**Log signal:**
```
Timed out while waiting for the machine to boot.
Failed to start VM for <name>
```
combined with the VM showing "Importing base box" (fresh import) even though
a previous run already created it.

**Root cause:**

The Vagrant state directory (`.vagrant/`) is out of sync with VirtualBox — most
commonly caused by:
- A previous `./run.sh clean` or `vagrant destroy` that was interrupted with Ctrl+C
  before finishing, leaving VMs partially destroyed
- The VM is still **running** in VirtualBox (old run) while Vagrant tries to create
  a new one on the same forwarded port — the new VM cannot bind the port → timeout

**Diagnose:**

```bash
# Check which VMs are currently running in Vagrant
cd vagrant_for_ansible
vagrant status

# Check which ports are occupied
ss -tlnp | grep -E '2204|2404|3223|4131'

# Check for orphaned VMs in VirtualBox (not tracked by Vagrant)
VBoxManage list runningvms
```

**Fix strategy:**

```bash
# Always the first thing to try — destroy all VMs and recreate
./run.sh clean all

# If vagrant destroy fails (VM not in Vagrant state but still in VirtualBox):
VBoxManage list vms
VBoxManage controlvm "<full_vm_name>" poweroff
VBoxManage unregistervm "<full_vm_name>" --delete

# Then retry:
./run.sh clean all
```

**Prevention:** Always use `./run.sh clean all` instead of interrupting a run
mid-way with Ctrl+C. If you must interrupt, run `./run.sh clean all` before
the next test run.

---

## Step 4 – Update run_status.md after fixing

After each successful run on a platform, update
`~/Documents/my_files/ansible/ansible_setup_my_host/run_status.md`:

```markdown
## Ubuntu 22.04
✅ OK - <date>

## Ubuntu 24.04
✅ OK - <date>

## Linux Mint 22.3 Zena
✅ OK - <date>

## Debian 13.1
✅ OK - <date>
```

If a platform has a known issue that is intentionally skipped with `ignore_errors`,
note it:

```markdown
## Ubuntu 25.04
⚠️ Skipped (commented out) – anki package not available
```

---

## Step 5 – The fix loop

Repeat until all targeted platforms pass:

```
1. Run: ./run.sh [options] 2>&1 | tee /tmp/ansible_run.log
2. Check exit code and scan log for FAILED / fatal:
3. If failures found:
   a. Classify each failure using Step 3 patterns
   b. Apply minimal fix to the correct file
   c. Do NOT re-run vagrant provisioning (vagrant up) separately –
      run.sh handles it
   d. Go to step 1
4. If no failures: update run_status.md and stop
```

**Important rules during the loop:**
- Fix **one root cause at a time** – do not batch unrelated fixes.
- After a fix to `group_vars/all/vars.yml`, the change takes effect on the next
  `./run.sh` without `clean` (no need to reprovision the VM).
- After a fix to a `tasks/*.yml` file, same – Ansible reruns all tasks on the
  already-running VM.
- Use `clean` only when the VM itself is broken (provisioning failed or SSH is down).
- If the same failure appears on 3 consecutive runs after a fix attempt, escalate
  by reading the full failing task file and checking upstream docs.

---

## Project file map (quick reference)

```
ansible_setup_my_host/
├── hosts                        ← SSH targets for Vagrant VMs + real hosts
├── run.yml                      ← main playbook (localhost / real hosts)
├── test_run.yml                 ← test playbook (Vagrant VMs, group: docker)
├── group_vars/all/vars.yml      ← apt_packages, apt_packages_known_issues,
│                                   flatpak_packages, nomachine_deb_url
├── tasks/
│   ├── main.yml                 ← orchestrates all tasks, with when: guards
│   ├── essential.yml            ← apt upgrade + apt_packages + flatpak
│   ├── collect_packages.yml     ← package_facts (must run before when: guards)
│   ├── set_ubuntu_codename.yml  ← sets {{ ubuntu_codename }} fact
│   ├── chrome.yml               ← .deb download pattern
│   ├── coolercontrol.yml        ← curl-script GPG pattern
│   ├── fzf.yml                  ← apt + .bashrc lineinfile
│   ├── grub-customizer.yml
│   ├── klogg.yml                ← GPG+repo pattern, hardcoded jammy
│   ├── nomachine.yml            ← .deb download via group_vars URL
│   ├── signal.yml               ← GPG+repo pattern
│   ├── spotify.yml
│   ├── sublime.yml
│   ├── tailscale.yml            ← curl | sh + TAILSCALE_KEY env
│   ├── virtualbox.yml
│   ├── vscode.yml               ← GPG+repo pattern (Microsoft)
│   ├── wireshark.yml
│   └── xdotool.yml
├── run_status.md                ← per-OS test results (update after each run)
└── vagrant_for_ansible/
    ├── Vagrantfile              ← VM definitions (ubuntu2204/2404, mint223zena, debian131)
    ├── run.sh                   ← test runner script
    │                               flags: ubuntu | debian | all | clean | help
    └── hosts                   ← (not used, main hosts file is at project root)
```

---

## Common one-liners

```bash
# Run only on latest Mint (default, fastest)
cd vagrant_for_ansible && ./run.sh

# Run only on Ubuntu LTS
./run.sh ubuntu

# Run on all, destroy first
./run.sh clean all

# Watch live output
./run.sh all 2>&1 | tee /tmp/run.log

# Grep for all failures after a run
grep -E "FAILED!|fatal:|ERROR" /tmp/run.log

# Grep for unreachable hosts
grep "UNREACHABLE" /tmp/run.log

# Count failed tasks per host
grep "FAILED!" /tmp/run.log | grep -oP '\[.*?\]' | sort | uniq -c
```
