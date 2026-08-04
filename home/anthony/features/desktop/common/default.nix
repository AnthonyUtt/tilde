{ pkgs, ... }: {
  imports = [
    ../browser/chromium.nix
    ../browser/zen

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
    claude-desktop-fhs
    feishin
    figma-linux
    gimp
    gnome-keyring
    inkscape
    jan-custom
    kdePackages.dolphin
    moonlight-qt
    obsidian
    orca-slicer
    playerctl
    pulseaudio
    pwvucontrol
    remmina
    slack
    spotify
    vlc
  ];

  services.kdeconnect.enable = true;
}
