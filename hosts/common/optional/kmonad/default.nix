{ inputs, ... }: {
  imports = [
    inputs.kmonad.nixosModules.default
  ];
}
