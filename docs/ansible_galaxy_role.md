# Publishing a role to Ansible Galaxy

## Prerequisites
- GitHub repository named `ansible-role-<rolename>` (e.g. `ansible-role-nomachine`)
- Role structure at repo root: `defaults/`, `tasks/`, `meta/main.yml`, `README.md`
- Account on [galaxy.ansible.com](https://galaxy.ansible.com) (login with GitHub)

## Publish

1. Import role on Galaxy:
   Galaxy → **Roles** → **Import Role** → select repo

2. Install:
   ```bash
   NETRC=/dev/null ansible-galaxy role install Varssos.nomachine
   ```

## Versioning

Tag releases with semver in the role repo:
```bash
git tag v1.0.0
git push origin main --tags
```
Then re-import on Galaxy (or configure GitHub webhook for automatic import on tag push).

Pin a version in `requirements.yml`:
```yaml
roles:
  - name: Varssos.nomachine
    version: v1.0.0
```

## Semver convention
- `v1.0.1` — bugfix
- `v1.1.0` — new feature (e.g. new distro support)
- `v2.0.0` — breaking change (e.g. renamed variable)

## netrc workaround

If Galaxy fails with `bad follower token 'protocol'` from `~/.netrc`:
```bash
NETRC=/dev/null ansible-galaxy role install Varssos.nomachine
# or
NETRC=/dev/null ansible-galaxy install -r requirements.yml
```
