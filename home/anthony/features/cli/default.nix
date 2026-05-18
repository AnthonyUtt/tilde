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
    csvtool
    eza
    ripgrep
    fastfetch
    fd
    fzf
    jq
    yarn
    zoxide
    direnv

    aviator-cli
    github-cli
  ];
}
