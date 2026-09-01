{ pkgs, ... }: {
  imports = [
    ./claude-code.nix
    ./cursor.nix
    ./pi.nix
  ];

  home.packages = with pkgs; [
    gemini-cli
    opencode
    opencode-desktop
  ];
}
