{
  description = "Starter flake for OCI images built with Nix (argunix-compatible)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      eachSystem =
        systems: f:
        builtins.foldl' (
          a: s: a // builtins.mapAttrs (k: v: (a.${k} or { }) // { ${s} = v; }) (f s)
        ) { } systems;

      inherit (inputs.nixpkgs) lib;
    in
    {
      # The overlay carries the image definitions. Consumers who just
      # want the images can add it to their own nixpkgs. Not per-system,
      # so it lives outside `eachSystem`.
      overlays.default = import ./overlay.nix;
    }
    // eachSystem systems (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };
      in
      {
        # Each image is a derivation whose output is the loadable image
        # tarball. The `meta.image-format = "docker"` attribute on the
        # derivation (see images/*.nix) is the one line argunix reads to
        # know it should publish the result as an OCI image.
        packages = pkgs.ociImages // {
          default = pkgs.ociImages.hello;
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        # NixOS-VM behavioural test: boots a small VM with docker, loads
        # each image tarball from the host store, runs the container and
        # checks its output. Gated to x86_64-linux because the test
        # framework needs KVM.
        #
        # The `pkgs` runNixOSTest hands to ./tests/hello.nix already has
        # the overlay applied, so the test simply references
        # `pkgs.ociImages.{hello,hello-static}` — no need to thread the
        # image derivations in by hand.
        checks.image-hello = pkgs.testers.runNixOSTest ./tests/hello.nix;
      }
    );
}
