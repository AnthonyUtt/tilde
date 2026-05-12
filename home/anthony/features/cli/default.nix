{ pkgs, ... }: {
  imports = [
    ./bat.nix
    ./btop.nix
    ./git.nix
    ./ssh.nix
    ./zellij.nix
    ./zsh
  ];

  home.packages = with pkgs; [
    eza
    ripgrep
    fastfetch
    fd
    fzf
    jq
    yarn
    zoxide
    direnv
  ];
}
