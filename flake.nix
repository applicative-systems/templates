{
  description = "Flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # for `nix flake check` on the subflakes
    template-default.url = "path:./default";
    template-default.inputs.nixpkgs.follows = "nixpkgs";

    template-docker-image.url = "path:./docker-image";
    template-docker-image.inputs.nixpkgs.follows = "nixpkgs";

    template-minimal.url = "path:./minimal";
    template-minimal.inputs.nixpkgs.follows = "nixpkgs";
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
      # template sub-flake whose `packages`, `checks` and `devShells`
      # we re-expose under `checks.<system>.<name>-<attr>`. Templates
      # that don't support a system contribute no attributes there
      # (the `or {}` fallbacks), so making a template platform-specific
      # needs no extra wiring. The `default` package is skipped because
      # by convention it aliases one of the named packages — checking
      # it again would just rebuild the same derivation under a second
      # name. `default` is kept for devShells (it's the primary shell,
      # not an alias).
      templateInputs = lib.filterAttrs (n: _: lib.hasPrefix "template-" n) inputs;

      templateChecksFor =
        system:
        lib.concatMapAttrs (
          inputName: input:
          let
            name = lib.removePrefix "template-" inputName;
            pkgs = lib.filterAttrs (n: _: n != "default") (input.packages.${system} or { });
            checks = input.checks.${system} or { };
            devShells = input.devShells.${system} or { };
          in
          lib.mapAttrs' (k: v: lib.nameValuePair "${name}-${k}" v) (pkgs // checks // devShells)
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
        minimal = {
          path = ./minimal;
          description = "Smallest possible starter flake — packages for every nixpkgs system via mapAttrs over legacyPackages";
        };
      };
    }
    // eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.treefmt.withConfig {
          settings = {
            tree-root-file = "flake.nix";
            on-unmatched = "info";
            formatter = {
              nixfmt = {
                command = lib.getExe pkgs.nixfmt;
                includes = [ "*.nix" ];
              };
              statix = {
                command = lib.getExe pkgs.statix;
                options = [ "fix" ];
                no-positional-arg-support = true;
                includes = [ "*.nix" ];
              };
              deadnix = {
                command = lib.getExe pkgs.deadnix;
                options = [ "--edit" ];
                includes = [ "*.nix" ];
              };
              prettier = {
                command = lib.getExe pkgs.prettier;
                options = [ "--write" ];
                includes = [
                  "*.css"
                  "*.html"
                  "*.js"
                  "*.json"
                  "*.md"
                  "*.yaml"
                  "*.yml"
                ];
              };
              shellcheck = {
                command = lib.getExe pkgs.shellcheck;
                includes = [
                  "*.sh"
                  "*.bash"
                ];
              };
              shfmt = {
                command = lib.getExe pkgs.shfmt;
                options = [
                  "-w"
                  "-i"
                  "2"
                  "-s"
                ];
                includes = [
                  "*.sh"
                  "*.bash"
                ];
              };
            };
          };
        };

        checks = {
          formatting = inputs.self.formatter.${system}.check inputs.self;
        }
        // templateChecksFor system;
      }
    );
}
