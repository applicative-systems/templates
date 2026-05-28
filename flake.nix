{
  description = "Flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # for `nix flake check` on the subflakes
    template-default.url = "path:./default";
    template-default.inputs.nixpkgs.follows = "nixpkgs";

    template-docker-image.url = "path:./docker-image";
    template-docker-image.inputs.nixpkgs.follows = "nixpkgs";
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

      inherit (inputs.nixpkgs) lib;

      # Every flake input named `template-<name>` is treated as a
      # template sub-flake whose `packages` and `checks` we re-expose
      # under `checks.<system>.<name>-<attr>`. Templates that don't
      # support a system contribute no attributes there (the `or {}`
      # fallbacks), so making a template platform-specific needs no
      # extra wiring. The `default` package is skipped because by
      # convention it aliases one of the named packages — checking it
      # again would just rebuild the same derivation under a second
      # name.
      templateInputs = lib.filterAttrs (n: _: lib.hasPrefix "template-" n) inputs;

      templateChecksFor =
        system:
        lib.concatMapAttrs (
          inputName: input:
          let
            name = lib.removePrefix "template-" inputName;
            pkgs = lib.filterAttrs (n: _: n != "default") (input.packages.${system} or { });
            checks = input.checks.${system} or { };
          in
          lib.mapAttrs' (k: v: lib.nameValuePair "${name}-${k}" v) (pkgs // checks)
        ) templateInputs;
    in
    {
      templates = {
        default = {
          path = ./default;
          description = "Minimal starter flake for a multi-system Nix project (eachSystem style)";
        };
        docker-image = {
          path = ./docker-image;
          description = "Starter flake for OCI images — plain and musl-static hello, with a NixOS integration test";
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

        checks = {
          formatting = treefmt.config.build.check inputs.self;
        }
        // templateChecksFor system;
      }
    );
}
