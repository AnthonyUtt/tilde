{
  description = "NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };
    hyprwm-contrib.url = "github:hyprwm/contrib";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        # IMPORTANT: To ensure compatibility with the latest Firefox version, use nixpkgs-unstable.
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    inherit (self) outputs;

    forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    overlays = {};

    mkNixos = modules: nixpkgs.lib.nixosSystem {
      inherit system;

      modules = modules ++ [
        ({ pkgs, ... }: {
          nixpkgs.overlays = builtins.attrValues overlays;
        })
      ];

      specialArgs = { inherit inputs outputs; };
    };
  in
  rec {
    nixosModules = import ./modules/nixos;

    # packages = forEachPkgs (pkgs: (import ./pkgs { inherit pkgs; }));

    nixosConfigurations = {
      titan = mkNixos [ ./hosts/titan ];
    };
  };
}
