{stdenv, rustc}: stdenv.mkDerivation {
  pname = "jonsbo-display";
  version = "1.0";
  src = ./display.rs;
  dontUnpack = true;
  nativeBuildInputs = [rustc];
  buildPhase = ''
    runHook preBuild
    rustc --edition=2024 -C opt-level=s -C lto -C codegen-units=1 \
      -C panic=abort -C debuginfo=0 "$src" -o jonsbo-display
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 jonsbo-display "$out/bin/jonsbo-display"
    runHook postInstall
  '';
}
