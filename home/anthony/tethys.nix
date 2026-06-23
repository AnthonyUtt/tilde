{ ... }: {
  imports = [
    ./global

    ./features/cli

    ./features/desktop/common
    ./features/desktop/hyprland
    ./features/desktop/wireless.nix

    ./features/editors/ai
    ./features/editors/nvim
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Override Hyprland configs
  xdg.configFile."hypr/custom/overrides.lua".text = ''
    hl.config({
      general = {
        layout = "scrolling",
      },
    })
  '';
}
