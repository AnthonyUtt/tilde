{ pkgs, lib, ... }: {
  fonts.packages = with pkgs; [
    departure-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    fira-code
    fira-code-symbols
    font-awesome
    geist-font
    material-symbols
    readex-pro
    space-grotesk
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
