{ ... }: {
  imports = [
    ./global

    ./features/cli

    ./features/desktop/common
    ./features/desktop/hyprland

    ./features/editors/ai
    ./features/editors/nvim
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
