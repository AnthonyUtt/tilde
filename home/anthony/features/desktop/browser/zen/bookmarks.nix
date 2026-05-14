{ ... }: {
  force = true;
  settings = [
    {
      name = "nixos";
      tags = [ "nix" ];
      keyword = "nixos";
      url = "https://search.nixos.org";
    }
    {
      name = "home manager";
      tags = [ "nix" ];
      keyword = "home";
      url = "https://home-manager-options.extranix.com/?query&release=master";
    }
  ];
}
