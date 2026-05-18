{ ... }: {
  imports = [
    ./dev-tools.nix
    ./doas.nix
    ./locale.nix
    ./nix.nix
    ./xdg.nix
    ./zsh.nix
  ];

  nixpkgs.config.allowUnfree = true;
}
