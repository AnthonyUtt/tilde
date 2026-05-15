{ inputs, pkgs, config, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.hyprland.homeManagerModules.default

    ../common/wayland
  ];

  home = {
    sessionVariables = { XDG_CURRENT_DESKTOP = "Hyprland"; };
    packages = with pkgs; [
      inputs.hyprwm-contrib.packages.${system}.grimblast
      inputs.rose-pine-hyprcursor.packages.${system}.default
      xdg-desktop-portal-gtk
      egl-wayland
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    plugins = with inputs.hyprland-plugins.packages.${system}; [ ];
    xwayland.enable = true;
    systemd.enable = false;
  };

  xdg.configFile.hypr = {
    source = ./config;
    recursive = true;
  };
}
