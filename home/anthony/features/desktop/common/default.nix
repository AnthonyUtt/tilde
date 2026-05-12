{ pkgs, ... }: {
  imports = [
    ./discord
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    gimp
    inkscape
    obsidian
    playerctl
    pulseaudio
    pwvucontrol
    remmina
    slack
    steam
    vlc
  ];
}
