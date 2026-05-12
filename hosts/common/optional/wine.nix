{ pkgs, inputs, ... }: {
  environment.systemPackages = [
    inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg
    pkgs.winePackages.waylandFull
  ];
}
