{
  lib,
  appimageTools,
  fetchurl,
  config,
  cudaPackages,
  cudaSupport ? config.cudaSupport,
}:
let
  pname = "Jan";
  version = "0.8.2";
  src = fetchurl {
    url = "https://github.com/janhq/jan/releases/download/v${version}/jan_${version}_amd64.AppImage";
    hash = "sha256-OWg8P4g2g+LVJU+SnjajG2cqWnzl5X2fjqTGkIC3kAY=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/Jan.desktop -t $out/share/applications
    sed -i '/Exec=Jan/c\Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 WEBKIT_DISABLE_COMPOSITING_MODE=1 GTK_CSD=0 Jan' $out/share/applications/Jan.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  extraPkgs =
    pkgs:
    lib.optionals cudaSupport [
      cudaPackages.cudatoolkit
    ];

  meta = {
    changelog = "https://github.com/janhq/jan/releases/tag/v${version}";
    description = "Jan is an open source alternative to ChatGPT that runs 100% offline on your computer";
    homepage = "https://github.com/janhq/jan";
    license = lib.licenses.asl20;
    mainProgram = "Jan";
    maintainers = [ ];
  };
}
