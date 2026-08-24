# dotfiles

Personal dotfiles for CachyOS, managed by
[chezmoi](https://www.chezmoi.io/).

## Bootstrap a fresh CachyOS installation

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- init --apply dadyarri
```

The first apply performs a full system upgrade, installs the declared official,
AUR, and Flatpak packages, applies the dotfiles, and then installs the language
toolchains and Fish plugins.

The package and toolchain manifests live in `.chezmoidata/`. Their installation
scripts use `run_onchange_`, so future `chezmoi apply` runs them again only after
the corresponding declaration changes.

Currently managed toolchains:

- Node.js 26 through fnm, with Corepack, pnpm, and Codex
- .NET SDK 10 through dotnet-install
- stable Rust through rustup
- Cargo tools and Fisher plugins declared in the repository

Authentication, secrets, hardware drivers, disk layout, and host-specific
system services are intentionally not automated. OpenLogi is also installed
from its official GitHub release rather than a package repository, so it remains
a manual post-bootstrap step.
