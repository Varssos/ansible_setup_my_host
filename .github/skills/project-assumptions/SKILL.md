---
name: project-assumptions
description: "Use when: adding a new app or tool to ansible_setup_my_host, deciding between group_vars/all/vars.yml and a roles/<app> git submodule, or writing a role README."
---

# Project assumptions

## Standalone vars app vs role as submodule
- If you install simple app with apt without configs etc you should add this to ./group_vars/all/vars.yml
- If app is more complexed to install or you have your own configs for that it's better to create separete roles/this_app/ as git submodule


## Roles
- Please write in each role in `README.md` how to install this role manually (example kitty). 
- Please make each role(submodule) as self-contained as possible. Put everything e.g. for kitty, tmux etc in that single role/submodule/project
- Roles that need stowed configs declare `dependencies: [{ role: dotfiles }]` in `meta/main.yml` (see bashrc, kitty, tmux).

