# ansible_setup_my_host

Supported platforms:
- Ubuntu:
    - 22.04
    - 24.04
    - 25.04
- Mint:
    - Wilma 22

## Prerequisities

First replace `ansible_user` in `hosts`

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
```

## Set tailscale key in env if you want to login automatically!
```
export TAILSCALE_KEY="HERE_YOUR_KEY_FROM_SETTINGS_AUTH_KEYS"
```

## Run

```
ansible-playbook run.yml -K
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
./run.sh
```


## Known issues
- [DEPRECATION WARNING]: The DependencyMixin is being deprecated. Modules should use community.general.plugins.module_utils.deps instead. This 
feature will be removed from community.general in version 9.0.0. Deprecation warnings can be disabled by setting deprecation_warnings=False in 
ansible.cfg.
Just type:
```
ansible-galaxy collection install community.general
```