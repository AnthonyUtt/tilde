{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Base linux stuff
    vim
    wget
    curl
    git

    # Compilers
    gcc

    # Network tools
    # tdns-cli

    # Misc
    zip
    unzip
  ];
}
