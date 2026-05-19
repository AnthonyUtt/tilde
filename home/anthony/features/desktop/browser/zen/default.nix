# See: https://github.com/luisnquin/nixos-config/blob/main/home/modules/programs/browser/zen/default.nix
{ pkgs, inputs, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    languagePacks = [ "en-US" ];

    setAsDefaultBrowser = true;
    # enablePrivateDesktopEntry = true;

    policies = import ./policies.nix;

    profiles.default = rec {
      settings = {
        "clipboard.autocopy" = false;
        "widget.use-xdg-desktop-portal.settings" = true;
        "zen.workspaces.continue-where-left-off" = true;
        "zen.workspaces.natural-scroll" = false;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.animate-sidebar" = false;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "float";
      };

      mods = [
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
        "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
        "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
        "c8d9e6e6-e702-4e15-8972-3596e57cf398" # Zen Back Forward
        "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
        "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
        "fd24f832-a2e6-4ce9-8b19-7aa888eb7f8e" # Quietify
      ];

      bookmarks = import ./bookmarks.nix;
      search = import ./search.nix { inherit pkgs; };

      containersForce = true;
      containers = {
        Personal = {
          color = "blue";
          icon = "fingerprint";
          id = 1;
        };
        Work = {
          color = "orange";
          icon = "briefcase";
          id = 2;
        };
        AntDev = {
          color = "purple";
          icon = "dollar";
          id = 3;
        };
      };

      pinsForce = true;
      pinsForceAction = "demote";
      # isEssential = false for standard pinned tabs
      pins = {
        "Email" = {
          id = "7b92de26-cca5-45a8-ada9-51eb1976686d";
          url = "https://mail.google.com";
          position = 101;
          isEssential = true;
          workspace = spaces."Work".id;
          container = containers.Work.id;
        };
        "Calendar" = {
          id = "cba528eb-d95d-49f7-bff8-a6bb721e2ffd";
          url = "https://calendar.google.com";
          position = 102;
          isEssential = true;
          workspace = spaces."Work".id;
          container = containers.Work.id;
        };
        "Linear" = {
          id = "5ae6cfdd-fba9-44eb-9c01-e3e4e52d43c3";
          url = "https://linear.app";
          position = 103;
          isEssential = true;
          workspace = spaces."Work".id;
          container = containers.Work.id;
        };
        "Github" = {
          id = "9049d73b-22a2-4e3e-bff4-8d78de8a77bc";
          url = "https://github.com/getrembrand/amplify";
          position = 104;
          isEssential = true;
          workspace = spaces."Work".id;
          container = containers.Work.id;
        };
      };

      # joinedTabs."Example" = {
      #   id = "example-id";
      #   gridType = "vsep"; # or hsep?
      #   tabs = [
      #     pins."Linear".id
      #     pins."Github".id
      #   ];
      #   # % of parent, must add up to 100
      #   sizes = [ 60 40 ];
      # };

      spacesForce = true;
      spaces = {
        "Work" = {
          id = "04a4312a-1ce2-4ed4-8d7a-863ecfb00a87";
          position = 1002;
          container = containers.Work.id;
          icon = "🚀";
          theme = {
            type = "gradient";
            colors = [
              {
                red = 98;
                green = 6;
                blue = 213;
                algorithm = "analogous";
                lightness = 43;
                primary = true;
                custom = false;
                position.x = 175;
                position.y = 97;
              }
              {
                red = 208;
                green = 6;
                blue = 153;
                algorithm = "analogous";
                lightness = 43;
                primary = false;
                custom = false;
                position.x = 240;
                position.y = 123;
              }
              {
                red = 6;
                green = 84;
                blue = 213;
                algorithm = "analogous";
                lightness = 43;
                primary = false;
                custom = false;
                position.x = 114;
                position.y = 129;
              }
            ];
            opacity = 0.5;
            texture = 0.6875;
          };
        };
        "Personal" = {
          id = "7c63557e-0149-4b75-9027-776b45c6b5de";
          position = 1001;
          container = containers.Personal.id;
          icon = "🏠";
          theme = {
            type = "gradient";
            colors = [
              {
                red = 218;
                green = 251;
                blue = 65;
                algorithm = "analogous";
                lightness = 62;
                primary = true;
                custom = false;
                position.x = 220;
                position.y = 294;
              }
              {
                red = 70;
                green = 251;
                blue = 73;
                algorithm = "analogous";
                lightness = 62;
                primary = false;
                custom = false;
                position.x = 118;
                position.y = 284;
              }
              {
                red = 251;
                green = 127;
                blue = 65;
                algorithm = "analogous";
                lightness = 62;
                primary = false;
                custom = false;
                position.x = 293;
                position.y = 221;
              }
            ];
            opacity = 0.5;
            texture = 0.6875;
          };
        };
        "AntDev" = {
          id = "da9e01bd-cba1-472b-b863-7c1c81a00e15";
          position = 1000;
          container = containers.AntDev.id;
          icon = "👾";
          theme = {
            type = "gradient";
            colors = [
              {
                red = 250;
                green = 26;
                blue = 70;
                algorithm = "analogous";
                lightness = 54;
                primary = true;
                custom = false;
                position.x = 282;
                position.y = 159;
              }
              {
                red = 243;
                green = 26;
                blue = 250;
                algorithm = "analogous";
                lightness = 54;
                primary = false;
                custom = false;
                position.x = 230;
                position.y = 87;
              }
            ];
            opacity = 0.6;
            texture = 0.6875;
          };
        };
      };
    };
  };
}
