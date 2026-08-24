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

The package and toolchain manifests live in `.chezmoidata/`. Their installation
scripts use `run_onchange_`, so future `chezmoi apply` runs them again only after
the corresponding declaration changes.

Currently managed toolchains:

- Node.js 26 through fnm, with Corepack, pnpm, and Codex
- .NET SDK 10 through dotnet-install
- stable Rust through rustup
- Cargo tools and Fisher plugins declared in the repository

Atuin, fnm, Starship, uv, rustup, and Zed are installed using their official
upstream installers. This keeps the system package database free of duplicate
language runtimes such as the `nodejs` and `npm` dependencies of Arch's Zed
package.

Authentication, secrets, hardware drivers, disk layout, and host-specific
system services are intentionally not automated.
