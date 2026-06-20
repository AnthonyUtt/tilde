{ pkgs, ... }: {
  imports = [
    ./claude-code.nix
    ./cursor.nix
  ];

  home.packages = with pkgs; [
    gemini-cli
    opencode
    opencode-desktop
  ];
}
