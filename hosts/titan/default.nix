{ pkgs, inputs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./hardware-configuration.nix

    ../common/global
    ../common/users/anthony

    ../common/optional/1password.nix
    ../common/optional/docker.nix
    ../common/optional/fonts.nix
    ../common/optional/gamemode.nix
    ../common/optional/greetd.nix
    ../common/optional/logitech.nix
    ../common/optional/pipewire.nix
    ../common/optional/wine.nix
  ];

  networking = {
    hostName = "titan";
    useDHCP = false;
    interfaces.enp7s0 = {
      useDHCP = true;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services = {
    dbus.implementation = "dbus";
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    gnome.gnome-keyring.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;
  };

  programs.dconf.enable = true;

  security.polkit.enable = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    users = {
      anthony = import ../../home/anthony/titan.nix;
    };
  };

  system.stateVersion = "26.05";
}
