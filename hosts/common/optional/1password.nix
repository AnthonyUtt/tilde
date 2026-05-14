{ pkgs, ... }: {
  environment.systemPackages = [ pkgs._1password-gui ];

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
      '';
      mode = "0755";
    };
  };
}
