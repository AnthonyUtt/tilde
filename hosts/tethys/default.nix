{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
    inputs.home-manager.nixosModules.home-manager

    ./hardware-configuration.nix

    ../common/global
    ../common/users/anthony

    ../common/optional/1password.nix
    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/fonts.nix
    ../common/optional/greetd.nix
    ../common/optional/kmonad
    ../common/optional/logitech.nix
    ../common/optional/pipewire.nix
    ../common/optional/wine.nix
    ../common/optional/wireless.nix
  ];

  networking = {
    hostName = "tethys";
    useDHCP = false;
    interfaces.wlp0s20f3 = {
      useDHCP = false;
    };
  };
  
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services = {
    kmonad = {
      enable = true;
      keyboards = {
        options = {
          name = "laptop";
          device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
          defcfg = {
            enable = true;
            fallthrough = true;
            allowCommands = false;
          };
          config = builtins.readFile ../common/optional/kmonad/colemak-dh-extend-ansi.kbd;
        };
      };
    };
    xserver = {
      enable = true;
      windowManager.i3.enable = true;
      displayManager.startx.enable = true;
    };
  };

  # Enable polkit for Sway/Wayland
  security.polkit.enable = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    users = {
      anthony = import ../../home/anthony/tethys.nix;
    };
  };

  system.stateVersion = "26.05";
}
