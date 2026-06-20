final: prev:
{
  aviator-cli = prev.callPackage ./aviator-cli.nix { };
  jan-custom = prev.callPackage ./jan.nix { };
}
