{ pkgs, ... }: {
  # Enable dconf to persist settings
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };
}
