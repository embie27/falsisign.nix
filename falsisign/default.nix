{ pkgs, falsisign-src, custom-rotation ? "seq .1 .1 .5" }:

let
  inherit (pkgs) stdenv lib;

  makeDerivation = { name, prePostFixup ? "" }:
    let
      runtimeInputs = let
        inputs = with pkgs; [
          coreutils
          file
          ghostscript
          imagemagick
        ] ++ lib.optional (name == "falsisign") [ poppler_utils (python39.withPackages(ps: [ ps.tkinter ])) ];
        in lib.makeBinPath inputs;
    in
    stdenv.mkDerivation {
      pname = name;
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
        cp $src/${name}.sh $out/bin/${name}
        cp $src/falsicoord.py $out/bin/falsicoord.py
        chmod +x $out/bin/${name}
      '';

      postFixup = prePostFixup + ''
        # replace bash
        substituteInPlace $out/bin/${name} --replace '#!/bin/bash' '#! ${pkgs.bash}/bin/bash'

        # fix path
        wrapProgram $out/bin/${name} --prefix PATH : ${runtimeInputs}
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
