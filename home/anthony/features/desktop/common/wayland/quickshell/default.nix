{ pkgs, inputs, lib, config, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qsBase = inputs.quickshell.packages.${system}.default;

  # quickshell's wrapper bakes in NIXPKGS_QT6_QML_IMPORT_PATH for a fixed set
  # of Qt6 modules (qtbase, qtdeclarative, qtwayland). Extend it with the extra
  # modules this config imports.
  extraQmlModules = (with pkgs.qt6Packages; [
    qt5compat        # Qt5Compat.GraphicalEffects
    qtpositioning    # QtPositioning
    qtmultimedia     # QtMultimedia
  ]) ++ (with pkgs.kdePackages; [
    syntax-highlighting  # org.kde.syntaxhighlighting
  ]);

  qsPkg = pkgs.symlinkJoin {
    name = "quickshell-with-extra-qml";
    paths = [ qsBase ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/quickshell \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${
          lib.concatMapStringsSep ":"
            (p: "${p}/lib/qt-6/qml")
            extraQmlModules
        }
    '';
  };

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
