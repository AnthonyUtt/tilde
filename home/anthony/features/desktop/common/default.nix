{ pkgs, ... }: {
  imports = [
    ./discord
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    gimp
    gnome-keyring
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
