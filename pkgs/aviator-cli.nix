{
  stdenv,
  fetchzip,
  lib,
  git,
}:
stdenv.mkDerivation (finalAttrs: rec {
  pname = "aviator-cli";
  binname = "av";
  version = "0.1.32";

  src = fetchzip {
    url = "https://github.com/aviator-co/av/releases/download/v${version}/av_${version}_linux_x86_64.tar.gz";
    sha256 = "sha256-wIwEOQO0Xg1zjTdUX0Y0q99prinY85RKFaeoyI/EtGM=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    git
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"/bin
    cp ./av "$out"/bin/av
    chmod +x "$out"/bin/av

    mkdir -p "$out"/share/licenses/av
    cp ./LICENSE "$out"/share/licenses/av/LICENSE

    mkdir -p "$out"/share/man/man1
    for manpage in $(ls ./man/man1); do
      cp ./man/man1/"$manpage" "$out"/share/man/man1/"$manpage"
    done

    runHook postInstall
  '';

  meta = {
    homepage = "https://aviator.co/";
    description = "CLI tool to create, update, review, and merge stacked PRs on GitHub.";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
})
