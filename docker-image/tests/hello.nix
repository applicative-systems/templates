{ pkgs, ... }:
{
  name = "image-hello";

  nodes.machine = {
    virtualisation.docker.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("docker.service")

    with subtest("plain hello image"):
        machine.succeed("docker load --input ${pkgs.ociImages.hello}")
        output = machine.succeed("docker run --rm hello:latest")
        assert "Hello, world!" in output, f"unexpected output: {output!r}"

    with subtest("musl-static hello image"):
        machine.succeed("docker load --input ${pkgs.ociImages.hello-static}")
        output = machine.succeed("docker run --rm hello-static:latest")
        assert "Hello, world!" in output, f"unexpected output: {output!r}"
  '';
}
