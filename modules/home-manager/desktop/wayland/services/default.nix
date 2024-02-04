{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = lib.utils.scanPaths ./.;

  options.modules.desktop.services = {
    swayidle = {
      enable = mkEnableOption "Swayidle";
      lockTime = mkOption {
        type = types.int;
        default = 3 * 60;
        description = "Lock screen after this many idle seconds";
      };
      screenOffTime = mkOption {
        type = types.int;
        default = 4 * 60;
        description = "Turn off screen after this many idle seconds";
      };
    };
    waybar.enable = mkEnableOption "Waybar";
    wlsunset.enable = mkEnableOption "wlsunset";
  };
}
