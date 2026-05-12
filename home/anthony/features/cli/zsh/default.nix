{ pkgs, lib, config, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -i";
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    history.ignoreAllDups = true;
    initContent = ''
      ${lib.strings.fileContents ./env.zsh}
      ${lib.strings.fileContents ./aliases.zsh}
      ${lib.strings.fileContents ./init.zsh}
    '';

    localVariables = {
      ZSH_DISABLE_COMPFIX = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "dotenv"
        "vi-mode"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
      }
      {
        name = "zsh-fzf-tab";
        src = pkgs.zsh-fzf-tab;
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
      }
      {
        name = "nix-zsh-completions";
        src = pkgs.nix-zsh-completions;
      }
    ];
  };
}
