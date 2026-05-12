{ pkgs, ... }: {
  imports = [
    ./bat.nix
    ./btop.nix
    ./git.nix
    ./ssh.nix
    ./tools.nix
    ./zellij.nix
    ./zsh
  ];

  home.packages = with pkgs; [
    eza
    ripgrep
    fd
    jq
    yarn
    zoxide
    direnv
  ];
}
