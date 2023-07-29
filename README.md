# ansible_setup_my_host

## Run

```
ansible-playbook run.yml -K
```



## Known issues
- [DEPRECATION WARNING]: The DependencyMixin is being deprecated. Modules should use community.general.plugins.module_utils.deps instead. This 
feature will be removed from community.general in version 9.0.0. Deprecation warnings can be disabled by setting deprecation_warnings=False in 
ansible.cfg.
Just type:
```
ansible-galaxy collection install community.general
```