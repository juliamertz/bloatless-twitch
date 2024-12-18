{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          pkgs,
          lib,
          system,
          ...
        }:
        let
          name = "twitch";
          buildInputs = with pkgs; [
            (pkgs.callPackage ./patched-streamlink.nix { })
            fzf
            mpv
            twitch-tui
          ];

          script = pkgs.stdenvNoCC.mkDerivation {
            inherit name;
            src = ./.;

            buildPhase = ''
              mkdir -p $out/bin
              install --mode +x ${./twitch.bash} $out/bin/twitch
            '';
          };
        in
        {
          packages.default = pkgs.symlinkJoin {
            inherit name;
            paths = [ script ] ++ buildInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
          };
        };
    };
}
