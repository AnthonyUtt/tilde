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
    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprland/hyprlang";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        # IMPORTANT: To ensure compatibility with the latest Firefox version, use nixpkgs-unstable.
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }@inputs:
  let
    inherit (self) outputs;

    system = "x86_64-linux";

    overlays = {
      rust-overlay = rust-overlay.overlays.default;
      personal = import pkgs/overlay.nix;
    };

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
  {
    nixosModules = import ./modules/nixos;

    # packages = forEachPkgs (pkgs: (import ./pkgs { inherit pkgs; }));

    nixosConfigurations = {
      titan = mkNixos [ ./hosts/titan ];
    };
  };
}
