{ pkgs, ... }: {
  imports = [
    ./git.nix
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
