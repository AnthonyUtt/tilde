{ pkgs, ... }:
let
  rubyDeps = pkgs.ruby_3_4.withPackages (p: with p; [
    solargraph
  ]);
in
{
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

      nodejs_24
      bash-language-server
      vscode-langservers-extracted
      docker-compose-language-service
      dot-language-server
      emmet-ls
      eslint
      kdePackages.qtdeclarative # for qml_ls
      lua-language-server
      nil
      prettier
      rubyDeps
      rust-analyzer
      (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default))
      sqls
      tailwindcss-language-server
      typescript-language-server
      glsl_analyzer
    ];
  };

  xdg.configFile = {
    nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
