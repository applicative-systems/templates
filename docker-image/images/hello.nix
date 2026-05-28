{
  lib,
  dockerTools,
  hello,
}:
dockerTools.buildLayeredImage {
  name = "hello";

  tag = "latest";

  config.Cmd = [ (lib.getExe hello) ];

  meta.image-format = "docker";
}
