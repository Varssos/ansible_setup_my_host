# ansible_setup_my_host

Supported platforms:
- Ubuntu:
    - 22.04
    - 24.04
- Mint:
    - Zena 22.3
- Debian:
    - 13.1

Temporarily disabled:
- Ubuntu 25.04
- Mint Zara 22.2

## Config/variables

- Replace `ansible_user` in `hosts`
- In `group_vars/all/vars.yml` set `is_private_machine` to `true` or `false`

## Add submodules

```
git submodule init
git submodule update --init --remote --recursive
```

## Install git and ansible

```
sudo apt update
sudo apt install git
sudo apt install ansible-core
```

## Install galaxy dependencies
```
ansible-galaxy install -r requirements.yml
# Or in case of netrc issues:
NETRC=/dev/null ansible-galaxy install -r requirements.yml
```

## Set tailscale key in env if you want to login automatically!
```
export TAILSCALE_KEY="HERE_YOUR_KEY_FROM_SETTINGS_AUTH_KEYS"
```

## Run

```
ansible-playbook run.yml -K
# Or on private machine
ansible-playbook run.yml -K -e "is_private_machine=true"
```

## TODO after installation
### Install private dotfiles
```
cd ~/
git clone https://github.com/Varssos/dotfiles_private.git
cd dotfiles_private
./setup_env.sh
```


## Tests
Run ansible on vagrant VMs. Check `vagrant_for_ansible/README.md`
```
cd vagrant_for_ansible
./run.sh all          # test on all supported platforms
./run.sh ubuntu       # test only on latest Ubuntu LTS
./run.sh debian       # test only on latest Debian
./run.sh halt all     # fix stuck VMs (fast, no rebuild)
./run.sh snap-restore all  # reset VMs to clean state (~30s, faster than clean)
./run.sh snap-save all     # save snapshot after first successful provisioning
./run.sh clean all    # full rebuild — use only when provisioning is broken
```


## Useful docs

- [Publishing a role to Ansible Galaxy](docs/ansible_galaxy_role.md)

## Known issues
- `spotify-client` requires `libc6 >= 2.39` — not installable on Ubuntu 22.04 (has 2.35). Skipped with `ignore_errors`.
- `anki` not available on Debian 13.1. Skipped with `ignore_errors`.
- `grub-pc` ends up in partially-configured state after Vagrant provisioning on Debian — worked around with a `debconf-set-selections` pre-task in `tasks/essential.yml`.
- [DEPRECATION WARNING]: The DependencyMixin is being deprecated. Modules should use community.general.plugins.module_utils.deps instead. This 
feature will be removed from community.general in version 9.0.0. Deprecation warnings can be disabled by setting deprecation_warnings=False in 
ansible.cfg.
Just type:
```
ansible-galaxy collection install community.general
```
