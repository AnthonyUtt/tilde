{ ... }: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = false;
    installVimSyntax = true;
    settings = {
      theme = "Bluloco Dark";
      font-family = "ComicShannsMono Nerd Font Mono";
      mouse-scroll-multiplier = 0.25;
    };
  };
}
