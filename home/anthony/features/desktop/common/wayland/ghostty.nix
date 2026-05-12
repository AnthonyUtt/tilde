{ ... }: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    installVimSyntax = true;
    settings = {
      theme = "Bluloco Dark";
      font-family = "ComicShannsMono Nerd Font Mono";
    };
  };
}
