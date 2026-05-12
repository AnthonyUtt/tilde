{ pkgs, ... }: {
  home.packages = with pkgs; [
    neofetch
    ventoy-latest
  ];
}
