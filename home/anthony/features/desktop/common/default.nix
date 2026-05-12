{ pkgs, ... }: {
  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    gimp
    inkscape
    obsidian
    playerctl
    remmina
    slack
    steam
    vlc
  ];
}
