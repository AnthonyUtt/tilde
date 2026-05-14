{ lib, pkgs, config, inputs, ... }:
let
  overlays = {
    rust-overlay = inputs.rust-overlay.overlays.default;
    claude-code = inputs.claude-code.overlays.default;
  };
in
{
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = builtins.attrValues overlays;
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "anthony";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
  };

  xdg.enable = true;
}
