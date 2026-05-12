{ pkgs, ... }: {
  home.packages = [
    (pkgs.discord.override {
      withVencord = true;
    })
  ];

  xdg.configFile = {
    "discord/settings.json".source = ./settings.json;
    "vesktop" = {
      recursive = true;
      source = ./vesktop;
    };
  };
}
