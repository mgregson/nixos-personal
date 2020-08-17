{ pkgs ? import <nixpkgs> {} }:
with pkgs;

let
  tanuki-aarch64 = stdenv.mkDerivation {
    pname = "tanuki";
    version = "3.5.43";
    src = fetchurl {
      url = "https://download.tanukisoftware.com/wrapper/3.5.43/wrapper-linux-armhf-64-3.5.43.tar.gz";
      sha256 = "e0c38061d259ec18be04b43077c28a06b3c13f62e6c6e0af6eebeb4a9b8bc098";
    };
    installPhase = ''
      mkdir -p $out
      mv * $out
      chmod a+x $out/bin/wrapper
    '';
  };
  sharedBuildInputs = [ gettext procps coreutils adoptopenjdk-jre-bin nix ];
  platformInstallSteps = version:
    # Special-case for aarch64, because the included Tanuki wrapper doesn't work
    # so we need to fetch an external one. SIGAR doesn't work either, but that
    # isn't solved yet.
    if stdenv.hostPlatform.isAarch64
    then ''
      cp ${tanuki-aarch64}/bin/wrapper $out/wrapper
      chmod a+x $out/wrapper
      ln -s ${tanuki-aarch64}/lib/libwrapper.so $out/${version}/bin/native/lib/
      rm $out/${version}/lib/wrapper-3.5.33.jar
      ln -s ${tanuki-aarch64}/lib/wrapper.jar $out/${version}/lib/wrapper-3.5.43.jar
    ''
    else
      let
        wrapperOS = "linux";
        wrapperBits = if stdenv.hostPlatform.is64bit
                      then "64"
                      else "32";
        wrapperArch = "x86";
        wrapperPath = "wrapper-${wrapperOS}-${wrapperArch}-${wrapperBits}";
      in
        ''
          mv ${version}/bin/native/lib/* $out/${version}/bin/native/lib/
          mv ${version}/bin/native/lib/.sigar_shellrc $out/${version}/bin/native/lib/
          mv tanuki/${wrapperPath} $out/wrapper
          chmod a+x $out/wrapper
        '';
in
stdenv.mkDerivation rec {
  pname = "sumologic";
  version = "19.288-10";
  src = fetchurl {
    url = "https://collectors.us2.sumologic.com/rest/download/tar?version=${version}";
    sha256 = "f4f47a1ae86cebb69c71845a27de293c6608318cdc99e22af9070696a8b454d0";
    name = "${pname}-${version}.tar.gz";
  };
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = if stdenv.hostPlatform.isAarch64
                then [ tanuki-aarch64 ] ++ sharedBuildInputs
                else sharedBuildInputs;
  installPhase = ''
    mkdir -p $out
    mv certs license script .install4j $out
    mkdir -p $out/${version}/bin/native/lib
    mv ${version}/bin/collector ${version}/bin/jvm.options $out/${version}/bin/
    mv ${version}/lib ${version}/optional-lib $out/${version}/
    mv config $out/config-static
    substituteAll collector $out/collector
    sed -i '1c#! ${coreutils}/bin/env ${nix}/bin/nix-shell' $out/collector
    sed -i '2i#! nix-shell -i bash -p gettext -p procps -p coreutils' $out/collector
    sed -i 's:^PS_BIN=.*:PS_BIN="${procps}/bin/ps":g' $out/collector
    sed -i 's:^TR_BIN=.*:TR_BIN="${coreutils}/bin/tr":g' $out/collector
    sed -i 's:^WRAPPER_CONF=.*:WRAPPER_CONF="$CONFIGURATION_DIRECTORY/wrapper.conf":g' $out/collector
    sed -i 's:^PIDDIR=.*:PIDDIR="$RUNTIME_DIRECTORY":g' $out/collector
    sed -i 's:wrapper\.logfile=.*:wrapper.logfile=/var/log/sumologic/collector.out.log:g' $out/config-static/wrapper.conf
    sed -i 's:''${JAVA_COMMAND_LOCATION}:${adoptopenjdk-jre-bin}/bin/java:g' $out/config-static/wrapper.conf
    sed -i 's|''${sys:SUMO_INSTALLATION_DIRECTORY:-.}|/var/log/sumologic|g' $out/config-static/log4j2.xml
    ${platformInstallSteps version}
    ln -s /var/lib/sumologic $out/config
    for d in alerts cache metrics-cache sink-cache data; do
      ln -s "/var/lib/sumologic/$d" "$out/$d"
    done
    chmod a+x $out/collector
  '';

  meta = {
    description = "SumoLogic Collector";
    homepage = "https://sumologic.com";
    platforms = builtins.filter (x: stdenv.lib.strings.hasInfix "linux" x) (stdenv.lib.platforms.aarch64 ++ stdenv.lib.platforms.x86);
    license = stdenv.lib.licenses.unfree;
  };
}
