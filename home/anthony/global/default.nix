{ lib, pkgs, config, inputs, ... }: {
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.claude-code.overlays.default
    ];
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
