{ pkgs, ... }: {
  force = true;
  default = "searxng";
  privateDefault = "searxng";
  engines = let
    nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  in {
    "searxng" = {
      urls = [
        {
          template = "https://search.uttho.me/search";
          params = [
            {
              name = "q";
              value = "{searchTerms}";
          }
          ];
        }
      ];
      definedAliases = [ "@searxng" ];
    };
    "Nix Packages" = {
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "channel";
              value = "unstable";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = nixSnowflakeIcon;
      definedAliases = [ "@pkgs" ];
    };
    "Nix Options" = {
      urls = [
        {
          template = "https://search.nixos.org/options";
          params = [
            {
              name = "channel";
              value = "unstable";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = nixSnowflakeIcon;
      definedAliases = [ "@pkgs" ];
    };
    "Home Manager Options" = {
      urls = [
        {
          template = "https://home-manager-options.extranix.com/";
          params = [
            {
              name = "query";
              value = "{searchTerms}";
            }
            {
              name = "release";
              value = "master"; # unstable
            }
          ];
        }
      ];
      icon = nixSnowflakeIcon;
      definedAliases = ["hmop"];
    };
  };
}
