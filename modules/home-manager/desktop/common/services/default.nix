{ lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkOption types mkAliasOptionModule;
in
{
  imports = lib.utils.scanPaths ./. ++ [
    (mkAliasOptionModule
      [ "darkman" ]
      [ "modules" "desktop" "services" "darkman" ])
  ];

  options.modules.desktop.services = {
    darkman = {
      enable = mkEnableOption "Darkman";

      switchScripts = mkOption {
        type = types.attrsOf (types.functionTo types.lines);
        default = { };
        description = ''
          Attribute set of functions that accept a string "dark" or "light"
          and provide a script for making the theme switch.
        '';
      };

      switchApps = mkOption {
        type = types.attrsOf types.attrs;
        default = { };
        example = lib.literalExpression ''
          {
            waybar = {
              paths = [ "waybar/config" "waybar/style.css" ];
              # Optionally provide a custom color format for subsitutions
              format = c: "#''${c}";
              # Optionally override colors
              colors = config.modules.colorScheme.colorsMap // {
                base00 = {
                  dark = colors.base04;
                  light = colors.base03;
                };
              };
            };
          }
        '';
        description = ''
          Attribute set of applications that should have color scheme switching
          applied to them.
        '';
      };
    };

    dunst = {
      enable = mkEnableOption "Dunst";

      monitorNumber = mkOption {
        type = types.int;
        default = 1;
        description = "The monitor number to display notifications on";
      };
    };

    wallpaper = {
      randomise = mkEnableOption "random wallpaper selection";

      default = mkOption {
        type = types.package;
        default = inputs.nix-resources.packages.${pkgs.system}.wallpapers.rx7;
        description = ''
          The default wallpaper to use if randomise is false.
        '';
      };

      randomiseFrequency = mkOption {
        type = types.str;
        default = "weekly";
        description = ''
          How often to randomly select a new wallpaper. Format is for the systemd timer OnCalendar option.
        '';
        example = "monthly";
      };

      setWallpaperCmd = mkOption {
        type = types.nullOr types.str;
        default = "";
        description = ''
          Command for setting the wallpaper. Must accept the wallpaper image path appended as an argument.
        '';
      };
    };
  };
}
