---
name: ansible-create-role
description: >
  Skill for creating a new Ansible role in the ansible_setup_my_host project
  following the established conventions (chrome, nomachine). Covers role structure,
  task conventions (idempotency, become, cleanup), defaults, meta for Galaxy,
  README, integration into run.yml and tasks/main.yml, .gitignore, and
  post-creation checklist for GitHub and Ansible Galaxy.
  Project root: ~/Documents/my_files/ansible/ansible_setup_my_host
---

# ansible-create-role

## Overview

Every role in this project follows the same structure and conventions.
Use this skill when asked to create a new Ansible role to replace a task in
`tasks/` or add a new capability.

---

## Role structure

```
roles/<rolename>/
  defaults/
    main.yml    # user-overridable variables (lowest priority)
  tasks/
    main.yml    # all tasks
  meta/
    main.yml    # Galaxy metadata (author, platforms, tags)
  README.md     # documentation
```

Do NOT create `vars/` unless the role needs internal constants that must not be
overridden (e.g. distro-specific package names). For user-facing defaults, always
use `defaults/`.

---

## defaults/main.yml conventions

- Comment header with the tool name
- Variables prefixed with `<rolename>_`
- Typical variables: `_deb_url`, `_deb_file`, `_package_name`, `_service_name`

Example (`roles/nomachine/defaults/main.yml`):
```yaml
# NoMachine
nomachine_deb_url: "https://www.nomachine.com/free/linux/64/deb"
nomachine_deb_file: "nomachine.deb"
nomachine_service_name: "nxserver"
```

---

## tasks/main.yml conventions

### Idempotency
Always check if already installed with `dpkg-query` before downloading/installing:

```yaml
- name: Check if <Tool> is already installed
  ansible.builtin.command: dpkg-query -W {{ <rolename>_package_name }}
  register: <rolename>_installed
  failed_when: false
  changed_when: false
```

Guard all install tasks with `when: <rolename>_installed.rc != 0`.

### Download
```yaml
- name: Download <Tool> .deb package
  ansible.builtin.get_url:
    url: "{{ <rolename>_deb_url }}"
    dest: "/tmp/{{ <rolename>_deb_file }}"
    mode: '0644'
  when: <rolename>_installed.rc != 0
```

### Install
```yaml
- name: Install <Tool>
  ansible.builtin.apt:
    deb: "/tmp/{{ <rolename>_deb_file }}"
  become: true
  when: <rolename>_installed.rc != 0
```

Do NOT use `update_cache: true` with `deb:` — it has no effect for local .deb files.

### Cleanup
Always remove the .deb from /tmp after install:
```yaml
- name: Remove temporary .deb package
  ansible.builtin.file:
    path: "/tmp/{{ <rolename>_deb_file }}"
    state: absent
  when: <rolename>_installed.rc != 0
```

### Service (if applicable)
```yaml
- name: Ensure <Tool> service is enabled and running
  ansible.builtin.service:
    name: "{{ <rolename>_service_name }}"
    state: started
    enabled: true
  become: true
```

### become placement
- `become: true` goes on individual tasks that need it (apt, service, privileged file ops)
- Do NOT rely solely on global `become: yes` in the playbook — be explicit in the role

### FQCN
Always use fully qualified collection names: `ansible.builtin.apt`, `ansible.builtin.get_url`, etc.

---

## meta/main.yml conventions

```yaml
---
galaxy_info:
  author: Varssos
  description: Install <Tool> on Debian/Ubuntu systems
  license: MIT
  min_ansible_version: "2.9"

  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
        - noble
    - name: Debian
      versions:
        - bullseye
        - bookworm
    - name: Linux Mint
      versions:
        - "21"
        - "22"

  galaxy_tags:
    - <rolename>
    - <category>

dependencies: []
```

License is always MIT. Do not use GPL for Ansible roles — it causes enterprise adoption issues.

---

## README.md conventions

Follow this exact structure (see `roles/nomachine/README.md` as reference):

```markdown
# <rolename>

Ansible role to install [<Tool>](<homepage>) on Debian/Ubuntu systems.

## Requirements

- Debian or Ubuntu host
- `become: true` privileges (sudo)

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `<rolename>_deb_url` | `<url>` | URL to download the `.deb` package from |
| `<rolename>_deb_file` | `<file>` | Filename used when saving the package to `/tmp` |
| `<rolename>_package_name` | `<pkg>` | Package name used to check if already installed |

## Example Playbook

\`\`\`yaml
- hosts: all
  become: true
  roles:
    - role: <rolename>
\`\`\`

## License

MIT

## Author

Varssos
```

---

## Integration into the project

### 1. run.yml — add the role

```yaml
  roles:
    # ... existing roles ...
    - <rolename>
```

Roles in `run.yml` replace `include_tasks` in `tasks/main.yml`. After moving to a
role, remove or comment out the corresponding `include_tasks` line in `tasks/main.yml`.

### 2. tasks/main.yml — remove the old task include

Replace the `include_tasks` line with a comment:
```yaml
# <tool> is handled by the <rolename> role in run.yml
```

### 3. Delete the old task file

After confirming the role works correctly, delete the original task file:
```bash
rm tasks/<rolename>.yml
```

Do NOT delete it before testing — keep it until the role is verified on at least one platform.

### 4. .gitignore — Galaxy roles are auto-ignored

Galaxy-installed roles (format `namespace.rolename`) are already ignored via:
```
roles/*.*/
```
Local roles (no dot in name) are tracked normally in git.

---

## GitHub repository conventions

- Repo name: `ansible-role-<rolename>` (Galaxy strips the `ansible-role-` prefix automatically)
- The repo root must be the role root (not a subfolder)
- Minimum required files: `defaults/main.yml`, `tasks/main.yml`, `meta/main.yml`, `README.md`

---

## Post-creation checklist

After creating the role locally, provide this summary to the user:

### Local (done by the agent)
- [ ] `roles/<rolename>/defaults/main.yml` created
- [ ] `roles/<rolename>/tasks/main.yml` created (idempotent, become, cleanup)
- [ ] `roles/<rolename>/meta/main.yml` created
- [ ] `roles/<rolename>/README.md` created
- [ ] `run.yml` updated (role added)
- [ ] `tasks/main.yml` updated (old include_tasks removed/commented)
- [ ] `tasks/<rolename>.yml` deleted (after verifying role works)

### GitHub (manual)
- [ ] Create repo `ansible-role-<rolename>` on GitHub
- [ ] Copy role contents (`defaults/`, `tasks/`, `meta/`, `README.md`) to repo root
- [ ] `git tag v1.0.0 && git push origin main --tags`

### Ansible Galaxy (manual)
- [ ] Go to [galaxy.ansible.com](https://galaxy.ansible.com) → login with GitHub
- [ ] **Roles** → **Import Role** → select `ansible-role-<rolename>`
- [ ] Install: `NETRC=/dev/null ansible-galaxy role install Varssos.<rolename>`
- [ ] Add to `requirements.yml` if used across projects:
  ```yaml
  roles:
    - name: Varssos.<rolename>
      version: v1.0.0
  ```

### Versioning (ongoing)
When making changes to the role repo:
```bash
git tag v1.x.x
git push origin main --tags
```
Then re-import on Galaxy or use webhook for automation.
Semver: `v1.0.1` bugfix · `v1.1.0` feature · `v2.0.0` breaking change
