{ config, ... }:
let
  host = config.networking.hostName;
in
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      nrs = "doas nixos-rebuild switch --flake ~/source/nixos#${host}";
      nrt = "doas nixos-rebuild test --flake ~/source/nixos#${host}";
      ncg = "doas nix-collect-garbage --delete-older-than 1d";
    };
  };
}
