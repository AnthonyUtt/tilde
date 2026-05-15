{ pkgs, ... }:
let
  identityFile = "/home/anthony/.ssh/id_rsa";
  homelabHost = hostname: {
    inherit hostname;
    user = "anthony";
    identityFile = identityFile;
    extraOptions.PreferredAuthentications = "publickey";
  };
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = { };

      gh = {
        hostname = "github.com";
        user = "git";
        identityFile = identityFile;
        extraOptions.PreferredAuthentications = "publickey";
      };

      opnsense = (homelabHost "opnsense.utthome.local") // { user = "admin"; };
      hashbrown = homelabHost "hashbrown.utthome.local";
      homefry = homelabHost "homefry.utthome.local";
      spud = homelabHost "spud.utthome.local";
      gaia = homelabHost "gaia.utthome.local";
    };
  };
}
