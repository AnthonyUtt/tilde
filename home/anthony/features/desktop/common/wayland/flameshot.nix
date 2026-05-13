{ pkgs, ... }: {
  home.packages = [ pkgs.grim ];

  services.flameshot = {
    enable = true;
    settings = {
      # General = {
      #   useGrimAdapter = true;
      #   disabledGrimWarning = true;
      # };
    };
  };
}
