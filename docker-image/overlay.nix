_final: prev: {
  ociImages = prev.ociImages or { } // {
    hello = prev.callPackage ./images/hello.nix { };
    hello-static = prev.callPackage ./images/hello-static.nix { };
  };
}
