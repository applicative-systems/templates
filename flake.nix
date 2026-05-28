{
  description = "Flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      eachSystem =
        systems: f:
        builtins.foldl' (
          a: s: a // builtins.mapAttrs (k: v: (a.${k} or { }) // { ${s} = v; }) (f s)
        ) { } systems;
    in
    {
      templates = {
        default = {
          path = ./default;
          description = "Minimal starter flake for a multi-system Nix project (eachSystem style)";
        };
      };
    }
    // eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };

        treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };
      in
      {
        formatter = treefmt.config.build.wrapper;

        checks.formatting = treefmt.config.build.check inputs.self;
      }
    );
}
