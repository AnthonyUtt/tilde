{ pkgs, ... }: {
  imports = [
    ./discord
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/spotify" = "spotify.desktop";
      "x-scheme-handler/figma" = "figma-linux.desktop";
    };
  };

  home.packages = with pkgs; [
    feishin
    figma-linux
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
