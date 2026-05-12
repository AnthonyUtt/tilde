{ ... }: {
  imports = [
    ./dev-tools.nix
    ./doas.nix
    ./locale.nix
    ./nix.nix
    ./zsh.nix
  ];

  nixpkgs.config.allowUnfree = true;
}
