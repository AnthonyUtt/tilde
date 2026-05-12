{ pkgs, ... }: {
  imports = [
    ./ghostty.nix
  ];

  home.packages = with pkgs; [
    swaybg
    swaylock
    hyprpicker
    wl-clipboard
    cliphist
    wf-recorder
    wl-mirror
    pipewire
    wireplumber
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    # libsForQt5.polkit-kde-agent
  ];

  home.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };
}
