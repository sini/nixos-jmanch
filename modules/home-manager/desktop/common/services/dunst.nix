{
  lib,
  pkgs,
  config,
  osConfig,
  desktopEnabled,
  ...
}:
let
  inherit (lib)
    ns
    mkIf
    getExe'
    mkForce
    ;
  inherit (config.${ns}) desktop;
  inherit (config.${ns}.colorScheme) light;
  inherit (osConfig.${ns}.device) primaryMonitor;
  cfg = desktop.services.dunst;
  colors = config.colorScheme.palette;
  systemctl = getExe' pkgs.systemd "systemctl";
  dunstctl = getExe' config.services.dunst.package "dunstctl";
in
mkIf (cfg.enable && desktopEnabled) {
  services.dunst = {
    enable = true;

    settings = {
      global =
        let
          inherit (desktop.style)
            font
            cornerRadius
            gapSize
            borderWidth
            ;
        in
        {
          monitor = toString cfg.monitorNumber;
          follow = "none";
          enable_posix_regex = true;
          font = "${font.family} 13";
          icon_theme = config.gtk.iconTheme.name;
          show_indicators = true;
          format = "<b>%s</b>\\n<span font='11'>%b</span>";
          layer = "overlay";

          corner_radius = cornerRadius;
          width = builtins.floor (primaryMonitor.width * 0.14);
          height = "(0, ${toString (builtins.floor (primaryMonitor.height * 0.25))})";
          offset =
            let
              offset = (gapSize * 2) + borderWidth;
            in
            "${toString offset}x${toString offset}";
          gap_size = gapSize;
          frame_width = borderWidth;
          transparency = 100;

          mouse_left_click = "do_action";
          mouse_middle_click = "close_all";
          mouse_right_click = "close_current";
          sort = true;
          stack_duplicates = true;
          min_icon_size = 128;
          max_icon_size = 128;
          markup = "full";
        };

      fullscreen_delay_everything = {
        fullscreen = "show";
      };

      urgency_critical = {
        background = "#${colors.base00}b3";
        foreground = "#${colors.base07}";
        frame_color = "#${colors.base08}";
      };

      urgency_normal = {
        background = "#${colors.base00}b3";
        foreground = "#${colors.base07}";
        frame_color = "#${colors.base0E}";
      };

      urgency_low = {
        background = "#${colors.base00}b3";
        foreground = "#${colors.base07}";
        frame_color = "#${colors.base0D}";
      };
    };
  };

  darkman.switchApps.dunst = {
    paths = [ ".config/dunst/dunstrc" ];
    reloadScript = "${systemctl} restart --user dunst";

    colorOverrides = {
      base00 = {
        dark = "${colors.base00}b3";
        light = "${light.palette.base00}";
      };
    };
  };

  ${ns}.desktop.programs.locking = {
    preLockScript = "${dunstctl} set-paused true";
    postUnlockScript = "${dunstctl} set-paused false";
  };

  systemd.user.services.dunst = {
    Unit.After = mkForce [ "graphical-session.target" ];
    Service.Slice = "background${lib.${ns}.sliceSuffix osConfig}.slice";
  };

  desktop.hyprland.settings.layerrule = [
    "blur, notifications"
    "xray 0, notifications"
    "animation slide, notifications"
  ];
}
