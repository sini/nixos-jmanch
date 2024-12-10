{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.${lib.ns}.programs.images;
in
lib.mkIf cfg.enable {
  home.packages = with pkgs; [
    swayimg
    gthumb # image editor
  ];

  programs.zsh.shellAliases = {
    img = "swayimg";
    img-edit = "gthumb";
    screenshot-edit = "gthumb ${config.xdg.userDirs.pictures}/screenshots/*(.om[1])";
  };

  xdg.mimeApps.defaultApplications = lib.listToAttrs (
    map
      (type: {
        name = "image/${type}";
        value = [ "swayimg.desktop" ];
      })
      [
        "gif"
        "png"
        "jpeg"
        "webp"
      ]
  );
}
