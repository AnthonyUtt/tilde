{ ... }:
let
  identityFile = "/home/anthony/.ssh/id_rsa";
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "gh" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = identityFile;
        PreferredAuthentications = "publickey";
      };
    };
  };
}
