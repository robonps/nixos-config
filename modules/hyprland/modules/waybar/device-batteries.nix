{stdenv, rustc, pkg-config, upower, glib}: stdenv.mkDerivation {
  pname = "waybar-device-batteries";
  version = "1.0";
  src = ./device-batteries.rs;
  dontUnpack = true;
  nativeBuildInputs = [rustc pkg-config];
  buildInputs = [upower glib];
  buildPhase = ''
    runHook preBuild
    rustc --edition=2024 -C opt-level=2 -C debuginfo=0 \
      -L native="$(pkg-config --variable=libdir upower-glib)" \
      -L native="$(pkg-config --variable=libdir gio-2.0)" \
      "$src" -o waybar-device-batteries
    rustc --edition=2024 --test \
      -L native="$(pkg-config --variable=libdir upower-glib)" \
      -L native="$(pkg-config --variable=libdir gio-2.0)" \
      "$src" -o tests
    runHook postBuild
  '';
  doCheck = true;
  checkPhase = "./tests";
  installPhase = ''
    runHook preInstall
    install -Dm755 waybar-device-batteries "$out/bin/waybar-device-batteries"
    runHook postInstall
  '';
}
