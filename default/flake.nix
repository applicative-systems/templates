{
  description = "Minimal starter flake — replace the example `hello` package with your own";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
      in
      {
        packages = {
          default = pkgs.hello;
          inherit (pkgs) hello;
        };
      }
    );
}
