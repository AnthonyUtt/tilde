{ pkgs, ... }: {
  imports = [
    ./discord
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    feishin
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
