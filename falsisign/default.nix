{ pkgs, falsisign-src, custom-rotation ? "seq .1 .1 .5" }:

let
  inherit (pkgs) stdenv lib;

  makeDerivation = { bin, prePostFixup ? "" }:
    let
      runtimeInputs = let
        inputs = with pkgs; [
          coreutils
          file
          ghostscript
          imagemagick
        ] ++ lib.optional (bin == "falsisign") poppler_utils;
        in lib.makeBinPath inputs;
    in
    stdenv.mkDerivation {
      pname = bin;
      version = "0.1.0";

      nativeBuildInputs = [ pkgs.makeWrapper ];

      buildInputs = with pkgs; [ coreutils file ghostscript poppler_utils imagemagick ];

      src = falsisign-src;

      preBuild = ''
        for f in *.sh
        do
          substituteInPlace "$f" --replace '#!/bin/bash' '#! ${pkgs.bash}/bin/bash'
        done
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp $src/${bin}.sh $out/bin/${bin}
        chmod +x $out/bin/${bin}
      '';

      postFixup = prePostFixup + ''
        # replace bash
        substituteInPlace $out/bin/${bin} --replace '#!/bin/bash' '#! ${pkgs.bash}/bin/bash'

        # fix path
        wrapProgram $out/bin/${bin} --prefix PATH : ${runtimeInputs}
      '';

      meta = with lib; {
        homepage = "https://gitlab.com/edouardklein/falsisign";
        license = licenses.wtfpl;
        description = "Command-line tool to simulate a document print-sign-and-scan process. Save trees, ink, time, and stick it to the bureaucrats!";
        maintainers = [ maintainers.gvolpe ];
        platforms = platforms.all;
      };
    };
in
{
  falsisign = makeDerivation {
    name = "falsisign";
    prePostFixup = ''
      # apply custom rotation range - 'seq .1 .1 .5' is a much saner value than the default IMO (it reduces the rotation)
      substituteInPlace $out/bin/falsisign --replace 'seq 0 .1 2' '${custom-rotation}'
    '';
  };

  signdiv = makeDerivation {
    name = "signdiv";
  };
}
