{ pkgs, ... }: {
  home.packages = [ pkgs.libnotify ];
  services.mako {
    enable = true;
  };
}
