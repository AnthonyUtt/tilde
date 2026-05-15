{ pkgs, inputs, lib, config, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qsPkg = inputs.quickshell.packages.${system}.default;

  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    opencv4
    pillow
    numpy
    requests
    pyyaml
  ]);

  scriptDeps = with pkgs; [
    bash
    coreutils
    jq
    gawk
    gnused
    gnugrep
    findutils
    which
    matugen
    brightnessctl
    wireplumber
    playerctl
    cava
    grim
    slurp
    wl-clipboard
    cliphist
    hyprpicker
    wf-recorder
    ffmpeg
    imagemagick
    libnotify
    socat
    bc
    xdg-user-dirs
    libqalculate
    libsecret
    networkmanager
    pythonEnv
  ];

  qsConfig = pkgs.runCommand "quickshell-config" { } ''
    mkdir -p $out
    cp -r ${./config}/. $out/
    chmod -R u+w $out
    find $out/scripts -type f \( -name '*.sh' -o -name '*.py' \) \
      -exec chmod +x {} +
  '';
in
{
  home.packages = [ qsPkg ] ++ scriptDeps;

  home.sessionVariables.QUICKSHELL_VIRTUAL_ENV = "${pythonEnv}";

  xdg.configFile.quickshell = {
    source = qsConfig;
    recursive = true;
  };

  home.activation.seedQuickshellState =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${config.xdg.stateHome}/quickshell/user/generated/wallpaper"
      run mkdir -p "${config.xdg.stateHome}/quickshell/user/ai/chats"
      run mkdir -p "${config.xdg.cacheHome}/quickshell/media"
      run mkdir -p "${config.xdg.cacheHome}/quickshell/notifications"
      seedfile="${config.xdg.stateHome}/quickshell/user/generated/hypr-colors.lua"
      if [ ! -e "$seedfile" ]; then
        run install -m644 ${./seed/hypr-colors.lua} "$seedfile"
      fi
    '';
}
