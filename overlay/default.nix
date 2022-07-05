{ pkgs ? import <nixpkgs> { } }:

{
  sway-rename-workspace = pkgs.stdenv.mkDerivation {
    name = "sway-rename-workspace";
    unpackPhase = ":";
    buildPhase =
      ''
        cat > sway-rename-workspace <<EOF
        #!${pkgs.zsh}/bin/zsh
        # Script that renames current workspace from (index) to (index): name
        # Also has some icons to suggest

        # Generate the new PATH by hand, declaring dependencies
        # There was an easier way to do this...
        export PATH=${pkgs.lib.concatStringsSep ":" (map (x: x+"/bin") [ pkgs.bemenu pkgs.jq pkgs.sway] )}:$PATH

        # Declare colors, they will be used in the script itself
        TITLE_FOREGROUND_COLOR="#685da2"
        HIGHLIGHTED_FOREGROUND_COLOR="#a89dd7"
        EOF
        # A bit hacky, but better than the escape headache
        cat ${./scripts/rename-workspace} >> sway-rename-workspace
        chmod +x sway-rename-workspace
      '';
    installPhase =
      ''
        mkdir -p $out/bin
        cp sway-rename-workspace $out/bin/
      '';
  };
  scratchpad-terminal = let pkgName = "scratchpad-terminal"; in
    with pkgs; stdenv.mkDerivation rec {
      name = "${pkgName}";
      unpackPhase = ":";
      buildPhase =
        ''
          cat > ${pkgName} <<EOF
          #!${zsh}/bin/zsh
          export PATH=${lib.concatStringsSep ":" (map (x: x+"/bin") [ sway libnotify ] )}:$PATH
          export IPC_CMD="swaymsg"
          EOF
          cat ${./scripts/scratchpad-terminal} >> ${pkgName}
          chmod +x ${pkgName}
        '';
      installPhase =
        ''
          mkdir -p $out/bin
          cp ${pkgName} $out/bin/
        '';

    };
}
