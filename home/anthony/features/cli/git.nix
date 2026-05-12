{ pkgs, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user = {
        name = "AnthonyUtt";
        email = "anthony@anthonyutt.dev";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
