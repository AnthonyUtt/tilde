{ pkgs, ... }: {
  imports = [
    ./discord
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/spotify" = "spotify.desktop";
    };
  };

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
    spotify
    steam
    vlc
  ];
}
