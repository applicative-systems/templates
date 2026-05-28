{
  lib,
  dockerTools,
  pkgsStatic,
}:
dockerTools.buildLayeredImage {
  name = "hello-static";

  tag = "latest";

  config.Cmd = [ (lib.getExe pkgsStatic.hello) ];

  meta.image-format = "docker";
}
