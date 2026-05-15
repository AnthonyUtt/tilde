{ pkgs, config, ... }:
let
  stateRoot = "${config.xdg.stateHome}/quickshell/user/generated";
in
{
  home.packages = [ pkgs.matugen ];

  xdg.configFile."matugen/config.toml".text = ''
    [config]
    version_check = false

    [templates.m3colors]
    input_path = '~/.config/matugen/templates/colors.json'
    output_path = '${stateRoot}/colors.json'

    [templates.hyprland]
    input_path = '~/.config/matugen/templates/hyprland/colors.lua'
    output_path = '${stateRoot}/hypr-colors.lua'

    [templates.gtk3]
    input_path = '~/.config/matugen/templates/gtk-3.0/gtk.css'
    output_path = '~/.config/gtk-3.0/gtk.css'

    [templates.gtk4]
    input_path = '~/.config/matugen/templates/gtk-4.0/gtk.css'
    output_path = '~/.config/gtk-4.0/gtk.css'

    [templates.kde_colors]
    input_path = '~/.config/matugen/templates/kde/color.txt'
    output_path = '${stateRoot}/color.txt'

    [templates.wallpaper]
    input_path = '~/.config/matugen/templates/wallpaper.txt'
    output_path = '${stateRoot}/wallpaper/path.txt'
  '';

  xdg.configFile."matugen/templates" = {
    source = ./matugen/templates;
    recursive = true;
  };
}
