{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;

    extraPackages = with pkgs; [
      gcc
      gnumake
      curl
      git
      typescript
      silicon
    ];
  };

  xdg.configFile = {
    nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
