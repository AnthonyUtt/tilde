# ~

Personal NixOS configuration flake. Declaratively defines the full system for two
machines — `titan` (desktop) and `tethys` (laptop) — from the bootloader and kernel
up through services, GUI compositor, dotfiles, and per-user package set. This is the
working config running on both machines, not a reference example.

Everything except secrets lives in this repo: system packages, services, user
account, shell, editor, window manager, browser policies, terminal multiplexer,
custom packages, and overlay pins. A clean install of NixOS plus this flake
reproduces the machine.

## Fleet topology

| Host | Role | CPU / GPU | Display server | Network | Notes |
|------|------|-----------|----------------|---------|-------|
| `titan` | Desktop workstation, gaming, GPU dev | AMD CPU + NVIDIA GPU (proprietary driver, full composition pipeline) | Hyprland + XWayland | Wired (`enp7s0`) | Zen kernel, OpenSSH on :22, gamemode, wine, Docker w/ `nvidia-container-toolkit` |
| `tethys` | Daily-driver laptop (ThinkPad X1 Carbon Gen 9) | Intel + Iris Xe | Hyprland (no XWayland) with i3+startx fallback | WiFi (`wlp0s20f3`) | `nixos-hardware` module for the X1 9th gen, kmonad remapping the laptop keyboard to Colemak-DH, Bluetooth, `wireless` module |

The two hosts share the same user, the same shell environment, the same editor
config, and the same Hyprland setup. They diverge where the hardware forces them
to: NVIDIA vs Intel graphics, wired vs wireless networking, and a few
laptop-only modules (`bluetooth`, `kmonad`, `wireless`). `titan` additionally
opts into the gaming stack (`gamemode`, `wine`, NVIDIA container runtime); the
laptop does not.

## Repository structure

```
.
├── flake.nix                 # inputs, overlays, mkNixos helper, host outputs
├── flake.lock
├── pkgs/                     # custom packages + personal overlay
│   ├── default.nix
│   ├── overlay.nix           # exposes aviator-cli
│   └── aviator-cli.nix
├── hosts/
│   ├── titan/                # desktop
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── tethys/               # laptop
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── common/
│       ├── global/           # imported by every host
│       │   ├── default.nix
│       │   ├── dev-tools.nix
│       │   ├── doas.nix      # sudo replacement
│       │   ├── locale.nix
│       │   ├── nix.nix       # flakes, nix-command, warn-dirty off
│       │   ├── xdg.nix
│       │   └── zsh.nix
│       ├── optional/         # opted into per host
│       │   ├── 1password.nix
│       │   ├── bluetooth.nix
│       │   ├── docker.nix
│       │   ├── fonts.nix
│       │   ├── gamemode.nix
│       │   ├── greetd.nix
│       │   ├── kmonad/       # daemon + .kbd config
│       │   ├── logitech.nix
│       │   ├── pipewire.nix
│       │   ├── wine.nix
│       │   └── wireless.nix
│       └── users/
│           └── anthony/      # immutable user, groups, hashed password
└── home/
    └── anthony/
        ├── titan.nix         # host's home-manager entrypoint
        ├── tethys.nix        # host's home-manager entrypoint
        ├── global/           # always-on home config
        └── features/         # opt-in by importing the directory
            ├── cli/          # zsh, git, bat, btop, fzf, zellij, ssh, …
            ├── desktop/
            │   ├── common/   # wayland utils, discord, mime defaults, GUI apps
            │   ├── browser/zen/   # Zen browser w/ policies, search, bookmarks
            │   ├── hyprland/      # compositor config
            │   └── wireless.nix   # laptop-only WiFi UI
            └── editors/
                ├── ai/       # claude-code, cursor
                └── nvim/
```

Two layers, two scopes:

- **`hosts/`** — system-level NixOS config. Split into `common/global` (every host
  imports it), `common/optional` (host opts in by importing the file), `users/`
  (account, groups, password hash), and per-host directories (`titan/`,
  `tethys/`) that own the `hardware-configuration.nix` plus the list of optional
  modules to pull in.
- **`home/`** — home-manager config for the `anthony` user. Same shape: a
  `global/` directory imported by both hosts, plus a tree of `features/` that
  each host's `titan.nix` / `tethys.nix` selectively imports.

System and home are wired together inside each host's `default.nix`: it imports
`inputs.home-manager.nixosModules.home-manager` and points
`home-manager.users.anthony` at `home/anthony/<host>.nix`, so one
`nixos-rebuild switch` rebuilds both layers atomically.

### Flake inputs

| Input | Pin | Purpose |
|-------|-----|---------|
| `nixpkgs` | `nixos-unstable` | Base package set |
| `home-manager` | `nix-community/home-manager/master`, follows nixpkgs | User-level config |
| `hardware` | `nixos/nixos-hardware` | ThinkPad X1 9th gen profile for `tethys` |
| `hyprland` | git (with submodules), upstream `hyprwm/Hyprland` | Compositor — built from source via the flake to stay on tip |
| `hyprland-plugins`, `hyprwm-contrib`, `rose-pine-hyprcursor` | follows `hyprland` | Plugins / cursor theme |
| `quickshell` | `git.outfoxxed.me/outfoxxed/quickshell` | Wayland shell framework |
| `zen-browser` | `0xc000022070/zen-browser-flake/beta` | Zen browser binary |
| `nix-gaming` | `fufexan/nix-gaming` | Gaming-specific packages and tweaks |
| `rust-overlay` | `oxalica/rust-overlay` | Pinned Rust toolchains |
| `kmonad` | `kmonad/kmonad?dir=nix` | Keyboard remapper daemon |
| `claude-code` | `sadjow/claude-code-nix` | Claude Code CLI overlay |

All non-base inputs that need a nixpkgs follow it, so there's one nixpkgs in the
closure.

## Module design

The module pattern is **import-based composition, not option flags**. There is
no `modules.gaming.enable = true` toplevel switch — to give a host the gaming
stack, you import `hosts/common/optional/gamemode.nix` (and `wine.nix`,
`docker.nix`) from that host's `default.nix`. A file in `optional/` is "off"
for a host if and only if that host doesn't import it.

This trades flexibility for legibility: there's no indirection between "what's
turned on" and the host's import list. Reading `hosts/titan/default.nix`
top-to-bottom tells you everything the system runs.

Concerns split roughly along these lines:

- **System / always-on** (`hosts/common/global/`): shell (zsh), privilege
  escalation (doas), locale, XDG, Nix daemon settings, minimal dev tools. Every
  host gets these unconditionally.
- **System / opt-in** (`hosts/common/optional/`): hardware-adjacent or
  workflow-specific services — audio (pipewire), input (logitech, kmonad),
  network (bluetooth, wireless), display manager (greetd), containerization
  (docker), gaming (gamemode, wine), credentials agent (1password), fonts.
- **User / always-on** (`home/anthony/global/`): overlays into home-manager,
  XDG, session path, git baseline, dark-mode dconf.
- **User / opt-in** (`home/anthony/features/`): every CLI tool, GUI app,
  editor, and the compositor config. A feature is a directory with a
  `default.nix` that imports its siblings and declares `home.packages`.

What's shared vs host-specific:

- **Shared:** everything in `global/` (both layers), every `features/` directory
  imported by both hosts, the user account, shell, editor, compositor, browser.
- **`titan`-specific:** NVIDIA driver setup, gaming stack, wired networking,
  zen kernel, SSH server enabled.
- **`tethys`-specific:** ThinkPad X1 hardware profile, kmonad on the internal
  keyboard, WiFi, bluetooth, the `features/desktop/wireless.nix` home module,
  i3+startx as a fallback to Hyprland.

## Secrets management

**Not managed by the flake yet.** The repo is currently fully plaintext. The
user password is committed as a bcrypt hash, which is fine on its own;
anything more sensitive (SSH keys, API tokens, cloud creds) lives outside the
flake — either fetched on-demand from 1Password (whose agent and SSH
integration the flake does enable) or kept on the machine out-of-band.

This is a known gap. The plan is to migrate to `sops-nix` so that things like
WiFi PSKs, service tokens, and any future per-host credentials can live in
the repo as age-encrypted blobs decrypted at activation time. That work hasn't
landed yet because the current 1Password-centric workflow has covered
day-to-day needs.

## Update and rollback strategy

Cadence: roughly weekly. `nix flake update` bumps every input at once rather
than chipping away input-by-input; with one nixpkgs in the closure (everything
that can follows it), a coordinated bump avoids partial mismatches.

`titan` is the staging host. The desktop is the more forgiving environment to
break — it's wired, there's no battery to worry about, and if a rebuild
wedges the compositor I can ssh in from the laptop and roll back. Once a
generation has run cleanly on `titan` for a day or two, the same lockfile gets
applied to `tethys`.

Pin philosophy: `nixpkgs` tracks the `nixos-unstable` channel rather than a
fixed commit, so the freshness comes from how often `flake.lock` is bumped,
not from the channel ref. `flake.lock` is committed; updates are intentional
(`nix flake update`), never implicit on rebuild.

When an update breaks something, the rollback path depends on how bad it is:

- **Boots but is broken** — `sudo nixos-rebuild switch --rollback` to drop
  back to the previous generation in place.
- **Doesn't boot** — pick the prior generation from the systemd-boot menu and
  carry on from there.
- **The lockfile itself is the problem** — `git revert` the `flake.lock`
  bump, then `nixos-rebuild switch` fresh. This is the only path that also
  fixes the *next* rebuild, since the other two leave a bad lockfile checked
  in.

## Design decisions and tradeoffs

### Why NixOS + flakes

Three things in combination, which no other tool I tried gave me at once:

1. **Atomic rebuilds with a real rollback.** Every `nixos-rebuild switch`
   produces a new generation that's listed in the bootloader. A bad update is
   a one-keystroke recovery at boot, or an in-place `switch --rollback`. The
   psychological effect of this is bigger than the technical one: I'm willing
   to update aggressively because there's no scenario where I lose the
   machine.
2. **One source of truth across both machines.** `titan` and `tethys` share
   the same shell, editor, compositor, browser, and dotfiles because they
   both import the same modules from this repo. There's no drift to
   reconcile — if I change git config, both machines pick it up on the next
   rebuild.
3. **Bootstrap is one command, not a weekend.** `nixos-install --flake .#<host>`
   on bare hardware reconstructs the entire system. I don't have to remember
   what I installed six months ago to make some workflow work.

Ansible would have given me #2 but not really #1; chezmoi/stow would have
given me partial #2 for dotfiles only. Neither approach reaches into the
kernel, services, and package layer the way the NixOS module system does.

### Why this layout

The `hosts/{global,optional,users}` + `home/{global,features}` split is
borrowed from the [Misterio77/nix-config][1] / [Misterio77/nix-starter-config][2]
shape that's common in the community. Alternatives considered:

- **Single `modules/` directory with option-flag gating** (`config.modules.X.enable`).
  Rejected: adds an indirection layer for a two-host fleet and a single user;
  the import list in each host file is already short enough to read.
- **NixOS-only, no home-manager.** Rejected: home-manager owns the dotfiles
  I actually iterate on (zsh, Hyprland, neovim, git), and integrating it as
  a NixOS module means one rebuild covers both layers.
- **Per-host top-level directories with no `common/`.** Rejected: most of the
  config is shared; duplicating it would be worse than the current import
  layout.

### Pain points

The biggest one is Hyprland source builds. The `hyprland` input is pulled
as a git flake with submodules from upstream, which means every `nix flake
update` that touches Hyprland (or any of its plugins, since they `follow`
it) triggers a from-source rebuild of the compositor on the next
`nixos-rebuild switch`. On `titan` this is tolerable; on the laptop it's
long enough that I'll sometimes defer the rebuild to when I'm plugged in.
The tradeoff is intentional — tracking upstream Hyprland gives me fixes
faster than the nixpkgs-packaged version — but it's the part of the
workflow that most often makes me reconsider the input.

### What I'd restructure starting over

Set up `sops-nix` from day one. Retrofitting secrets management into an
existing flake means picking encryption boundaries after the fact and
auditing the history for anything sensitive that's already been committed.
Doing it on day one means the boundary is obvious from the start and there's
no plaintext-secret debt to pay down.

## Getting started / reproducing

Bootstrapping a fresh machine from this flake:

1. Boot the NixOS minimal installer, partition + format, mount to `/mnt`.
2. `nixos-generate-config --root /mnt` to produce a starting
   `hardware-configuration.nix`.
3. `git clone` this repo into `/mnt/etc/nixos` (or wherever).
4. Drop the generated `hardware-configuration.nix` into `hosts/<host>/`,
   replacing the committed one if the hardware genuinely differs from what's
   already there.
5. **Set the user password hash before installing.** `users.mutableUsers =
   false` is set in `hosts/common/users/anthony/`, so the `hashedPassword`
   in that file has to be a valid hash *at install time* — there's no
   `passwd` step after boot to fix it. Generate one with `mkpasswd -m yescrypt`
   and commit (or stash locally) before running `nixos-install`.
6. `nixos-install --flake .#<host>` (`titan` or `tethys`).
7. Reboot, log in as `anthony`.
8. **Post-install, manually:** sign into the 1Password desktop app and turn
   on the SSH agent + CLI integrations. The flake installs and enables the
   service, but the actual sign-in and key unlock is a manual step that
   can't (and shouldn't) be declarative.
9. `sudo nixos-rebuild switch --flake .#<host>` from inside the booted system
   to confirm everything reproduces cleanly.

Day-to-day rebuilds:

```sh
sudo nixos-rebuild switch --flake .#<host>     # apply now
sudo nixos-rebuild boot   --flake .#<host>     # apply on next boot
nix flake update                                # bump inputs (weekly-ish)
nix flake update nixpkgs                        # bump a single input
```

Rollback: pick a prior generation from the systemd-boot menu at boot, or
`sudo nixos-rebuild switch --rollback`. If the bad input is in `flake.lock`,
`git revert` the lockfile bump and rebuild so the next update doesn't
re-break.

[1]: https://github.com/Misterio77/nix-config
[2]: https://github.com/Misterio77/nix-starter-configs
