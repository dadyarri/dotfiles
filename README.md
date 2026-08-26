# dotfiles

Personal dotfiles for CachyOS, managed by
[chezmoi](https://www.chezmoi.io/).

## Bootstrap a fresh CachyOS installation

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply dadyarri
```

The first apply performs a full system upgrade, installs the declared Arch,
AUR, and Flatpak packages, applies the dotfiles, and then installs standalone
tools, language toolchains, and Fish plugins.

Package and toolchain manifests live in `.chezmoidata/`; standalone tools are
declared in `.config/update-standalone/tools.toml`. Their installation scripts
use `run_onchange_`, so future `chezmoi apply` runs them again only after the
corresponding declaration changes.

Currently managed toolchains:

- Node.js 26 through fnm, with Corepack, pnpm, and Codex
- .NET SDK 10 through dotnet-install
- stable Rust through rustup
- Cargo tools and Fisher plugins declared in the repository

Atuin, fnm, Starship, uv, the .NET installer, rustup, Zed, and Zen Browser are
installed using their official upstream installers. This keeps the system
package database free of duplicate language runtimes such as the `nodejs` and
`npm` dependencies of Arch's Zed package.

`upd` updates repository/AUR packages, Flatpaks, upstream-managed standalone
tools, language package managers, and Fish plugins. The standalone part can be
run independently with `update-standalone`; Zed and Zen Browser are omitted
after bootstrap because their official builds update themselves in the
background.

`audit-packages` compares the current system with the package manifest without
changing anything. It reports missing declarations, explicit foreign packages,
Flatpak drift, and orphaned pacman packages. Use `--verbose` to also list
official explicit packages outside the manifest, or `--fail-on-drift` for a
non-zero exit status when actionable findings exist.

## Validation

Run `scripts/check` from the source directory before pushing changes. It
validates the chezmoi source and rendered CachyOS scripts, runs ShellCheck and Fish
syntax checks, checks Python with Ruff and Basedpyright, and executes regression
tests for `update-standalone`. The same command runs in GitHub Actions.

Authentication, secrets, hardware drivers, disk layout, and host-specific
system services are intentionally not automated.
