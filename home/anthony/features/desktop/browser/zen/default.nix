# See: https://github.com/luisnquin/nixos-config/blob/main/home/modules/programs/browser/zen/default.nix
{ inputs, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    languagePacks = [ "en-US" ];

    setAsDefaultBrowser = true;
    # enablePrivateDesktopEntry = true;
  };
}
