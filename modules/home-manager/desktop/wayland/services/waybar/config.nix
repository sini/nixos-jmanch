{
  ns,
  lib,
  pkgs,
  config,
  hostname,
  osConfig',
  isWayland,
  ...
}:
let
  inherit (lib)
    mkIf
    optional
    getExe'
    toUpper
    mkForce
    getExe
    concatLines
    sort
    escapeShellArg
    concatMapStringsSep
    ;
  inherit (lib.${ns}) addPatches getMonitorByName;
  inherit (config.${ns}) desktop;
  inherit (desktop.services) hypridle;
  inherit (osConfig'.${ns}.device) gpu monitors;
  cfg = desktop.services.waybar;
  isHyprland = lib.${ns}.isHyprland config;
  colors = config.colorScheme.palette;
  gapSize = toString desktop.style.gapSize;

  audio = osConfig'.${ns}.system.audio;
  wgnord = osConfig'.${ns}.services.wgnord;
  gamemode = osConfig'.${ns}.programs.gaming.gamemode;
  gpuModuleEnabled = (gpu.type == "amd") && (gpu.hwmonId != null);
  systemctl = getExe' pkgs.systemd "systemctl";
in
mkIf (cfg.enable && isWayland) {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    # First patch disables Waybar reloading both when the SIGUSR2 event is sent
    # and when Hyprland reloads. Waybar reloading causes the bar to open twice
    # because we run Waybar with systemd. Also breaks theme switching because
    # it reloads regardless of the Hyprland disable autoreload setting.

    # The output bar patch allows for hiding, showing, or toggling the bar on
    # specific outputs by sending an encoded signal. The signal is 5 bits where
    # the first two bits are the action and the remaining 3 bits are the output
    # number. Actions are hide(0), show(1), toggle(2). This patch disables the
    # custom module signal functionality that I don't use.
    package =
      (addPatches
        (pkgs.waybar.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "0d02f6877d88551ea2be0cd151c1e6354e208b1c";
            hash = "sha256-Z2ZS4rD3FjNIblPlXpx9XhkvepZWhO4xnJNk7o5ebe0=";
          };
        })
        [
          ../../../../../../patches/waybarDisableReload.patch
          (
            let
              sortedMonitors = concatMapStringsSep ", " (m: "\"${m.name}\"") (
                sort (a: b: a.number < b.number) monitors
              );
            in
            pkgs.writeText "waybar-bar-toggle.patch" # cpp
              ''
                diff --git a/src/bar.cpp b/src/bar.cpp
                index 872632ac..ba578b1e 100644
                --- a/src/bar.cpp
                +++ b/src/bar.cpp
                @@ -405,6 +405,7 @@ void waybar::Bar::onMap(GdkEventAny*) {
                 }
                 
                 void waybar::Bar::setVisible(bool value) {
                +  if (value == visible) return;
                   visible = value;
                   if (auto mode = config.get("mode", {}); mode.isString()) {
                     setMode(visible ? config["mode"].asString() : MODE_INVISIBLE);
                diff --git a/src/main.cpp b/src/main.cpp
                index ff446ffc..131c8fb7 100644
                --- a/src/main.cpp
                +++ b/src/main.cpp
                @@ -93,8 +93,22 @@ int main(int argc, char* argv[]) {
                 
                     for (int sig = SIGRTMIN + 1; sig <= SIGRTMAX; ++sig) {
                       std::signal(sig, [](int sig) {
                +        std::vector<std::string> monitors = {${sortedMonitors}};
                +        int action = (sig - SIGRTMIN) >> 3;
                +        int monitorNum = (sig - SIGRTMIN) & ((1 << 3) - 1);
                +        if (monitorNum >= monitors.size() || monitorNum < 1) {
                +          spdlog::error("Monitor with number {} does not exist", monitorNum);
                +          return;
                +        }
                +        auto& monitorName = monitors[monitorNum - 1];
                         for (auto& bar : waybar::Client::inst()->bars) {
                -          bar->handleSignal(sig);
                +          if (bar->output->name == monitorName) {
                +            if (action == 2)
                +              bar->toggle();
                +            else
                +              bar->setVisible(action);
                +            break;
                +          }
                         }
                       });
                     }
              ''
          )
        ]
      ).override
        {
          cavaSupport = false;
          evdevSupport = true;
          experimentalPatches = false;
          hyprlandSupport = true;
          inputSupport = false;
          jackSupport = false;
          mpdSupport = false;
          mprisSupport = false;
          nlSupport = true;
          pulseSupport = true;
          rfkillSupport = false;
          runTests = false;
          sndioSupport = false;
          swaySupport = false;
          traySupport = true;
          udevSupport = false;
          upowerSupport = false;
          wireplumberSupport = false;
          withMediaPlayer = false;
        };

    settings = {
      bar = {
        layer = "top";
        height = 41;
        margin = "${gapSize} ${gapSize} 0 ${gapSize}";
        spacing = 17;

        "hyprland/workspaces" = mkIf isHyprland {
          on-click = "activate";
          sort-by-number = true;
          active-only = false;
          format = "{icon}";
          on-scroll-up = "hyprctl dispatch workspace m-1";
          on-scroll-down = "hyprctl dispatch workspace m+1";

          format-icons = {
            TWITCH = "󰕃";
            GAME = "󱎓";
          };
        };

        "hyprland/submap" = mkIf isHyprland {
          format = "{}";
          max-length = 8;
          tooltip = false;
        };

        "hyprland/window" = mkIf isHyprland {
          max-length = 59;
          separate-outputs = true;
        };

        clock = {
          interval = 1;
          format = "{:%H:%M:%S}";
          format-alt = "{:%e %B %Y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";

          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "";
            on-scroll = 1;

            format = {
              months = "<span color='#${colors.base07}'><b>{}</b></span>";
              days = "<span color='#${colors.base07}'><b>{}</b></span>";
              weekdays = "<span color='#${colors.base03}'><b>{}</b></span>";
              today = "<span color='#${colors.base0B}'><b>{}</b></span>";
            };
          };

          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        pulseaudio = mkIf audio.enable {
          format = "<span color='#${colors.base04}'>{icon}</span> {volume:2}%{format_source}";
          format-muted = "<span color='#${colors.base08}'>󰖁</span> {volume:2}%";
          format-source = "";
          format-source-muted = "<span color='#${colors.base08}'>  󰍭</span> Muted";

          format-icons = {
            headphone = "";
            hdmi = "󰍹";

            default = [
              "<span></span>"
              "<span>󰕾</span>"
              "<span></span>"
            ];
          };

          on-click = "${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          tooltip = false;
        };

        network = {
          interval = 5;
          format = "<span color='#${colors.base04}'>󰈀</span> {bandwidthTotalBytes}";
          tooltip-format = "<span color='#${colors.base04}'>󰇚</span>{bandwidthDownBytes:>} <span color='#${colors.base04}'>󰕒</span>{bandwidthUpBytes:>}";
          max-length = 50;
        };

        cpu = {
          interval = 5;
          format = "<span color='#${colors.base04}'></span> {usage}%";
        };

        "custom/gpu" = mkIf gpuModuleEnabled {
          format = "<span color='#${colors.base04}'>󰾲</span> {}%";
          exec = "${getExe' pkgs.coreutils "cat"} /sys/class/hwmon/hwmon${toString gpu.hwmonId}/device/gpu_busy_percent";
          interval = 5;
          tooltip = false;
        };

        memory = {
          interval = 30;
          format = "<span color='#${colors.base04}'></span> {used:0.1f}GiB";
          tooltip = false;
        };

        "network#hostname" = {
          format = toUpper hostname;
          tooltip-format-ethernet = "{ipaddr}";
          tooltip-format-disconnected = "<span color='#${colors.base08}'>Disconnected</span>";
        };

        tray = {
          icon-size = 17;
          show-passive-items = true;
          spacing = 17;
        };

        "custom/poweroff" = {
          format = "⏻";
          on-click-middle = "${systemctl} poweroff";
          tooltip = false;
        };

        "custom/vpn" = mkIf wgnord.enable {
          format = "<span color='#${colors.base04}'></span> {}";
          exec = "echo '{\"text\": \"${wgnord.country}\"}'";
          exec-if = "${getExe' pkgs.iproute2 "ip"} link show wgnord > /dev/null 2>&1";
          return-type = "json";
          tooltip = false;
          interval = 5;
        };

        "custom/hypridle" = mkIf hypridle.enable {
          format = "<span color='#${colors.base04}'>󰷛 </span> {}";
          exec = "echo '{\"text\": \"Lock Inhibited\"}'";
          exec-if = "${systemctl} is-active --quiet --user hypridle && exit 1 || exit 0";
          return-type = "json";
          tooltip = false;
          interval = 5;
        };

        gamemode = mkIf gamemode.enable {
          format = "{glyph} Gamemode";
          format-alt = "{glyph} Gamemode";
          glyph = "<span color='#${colors.base04}'>󰊴</span>";
          hide-not-running = true;
          use-icon = false;
          icon-size = 0;
          icon-spacing = 0;
          tooltip = false;
        };

        modules-left = [
          "custom/fullscreen"
          "hyprland/workspaces"
          "hyprland/submap"
          "hyprland/window"
        ];

        modules-center = [ "clock" ];

        modules-right =
          optional hypridle.enable "custom/hypridle"
          ++ [ "network" ]
          ++ optional wgnord.enable "custom/vpn"
          ++ [ "cpu" ]
          ++ optional gpuModuleEnabled "custom/gpu"
          ++ optional gamemode.enable "gamemode"
          ++ [ "memory" ]
          ++ optional audio.enable "pulseaudio"
          ++ [
            "tray"
            "custom/poweroff"
            "network#hostname"
          ];
      };
    };
  };

  systemd.user.services.waybar = {
    # Waybar spams restarts during shutdown otherwise
    Service.Restart = mkForce "no";
  };

  darkman.switchApps.waybar = {
    paths = [
      ".config/waybar/config"
      ".config/waybar/style.css"
    ];
    reloadScript = "${systemctl} restart --user waybar";
  };

  desktop.hyprland.settings =
    let
      inherit (config.${ns}.desktop.hyprland) modKey;
      hyprctl = escapeShellArg (getExe' config.wayland.windowManager.hyprland.package "hyprctl");
      jaq = getExe pkgs.jaq;

      monitorNameToNumMap = # bash
        ''
          declare -A monitor_name_to_num
          ${concatLines (
            map (
              m:
              "monitor_name_to_num[${m.name}]='${
                if m.mirror == null then
                  toString m.number
                else
                  toString (getMonitorByName osConfig' m.mirror).number
              }'"
            ) monitors
          )}
        '';

      toggleActiveMonitorBar = pkgs.writeShellScript "hypr-toggle-active-monitor-waybar" ''
        focused_monitor=$(${hyprctl} monitors -j | ${jaq} -r 'first(.[] | select(.focused == true) | .name)')
        # Get ID of the monitor based on x pos sort
        ${monitorNameToNumMap}
        monitor_num=''${monitor_name_to_num[$focused_monitor]}
        ${systemctl} kill --user --signal="SIGRTMIN+$(((2 << 3) | monitor_num))" waybar
      '';

      workspaceAutoToggle = pkgs.writeShellApplication {
        name = "hypr-waybar-workspace-auto-toggle";
        runtimeInputs = with pkgs; [
          coreutils
          socat
          systemd
        ];
        text = # bash
          ''
            ${monitorNameToNumMap}
            update_monitor_bar() {
              monitor_num=''${monitor_name_to_num["$1"]}
              if [[ ${
                concatMapStringsSep "||" (workspace: "\"$2\" == \"${workspace}\"") cfg.autoHideWorkspaces
              } ]]; then
                systemctl kill --user --signal="SIGRTMIN+$(((0 << 3) | monitor_num ))" waybar
              else
                systemctl kill --user --signal="SIGRTMIN+$(((1 << 3) | monitor_num ))" waybar
              fi
            }

            open_workspace() {
              workspace_name="''${1#*>>}"
              focused_monitor=$(${hyprctl} monitors -j | ${jaq} -r 'first(.[] | select(.focused == true) | .name)')
              update_monitor_bar "$focused_monitor" "$workspace_name"
            }

            move_workspace() {
              IFS=',' read -r -a args <<< "$1"
              workspace_name="''${args[0]#*>>}"
              monitor_name="''${args[1]}"
              update_monitor_bar "$monitor_name" "$workspace_name"

              # unhide/hide the bar on the monitor where this workspace came
              # from through all monitors and update the bar based on their
              # active workspace.
              active_workspaces=$(${hyprctl} monitors -j | ${jaq} -r ".[] | select((.disabled == false) and (.name != \"$monitor_name\")) | \"\(.name) \(.activeWorkspace.name)\"")
              while IFS= read -r line; do
                read -r monitor_name workspace_name <<< "$line"
                update_monitor_bar "$monitor_name" "$workspace_name"
              done <<< "$active_workspaces"
            }

            handle() {
              case $1 in
                workspace\>*) open_workspace "$1" ;;
                moveworkspace\>*) move_workspace "$1" ;;
              esac
            }

            socat -U - UNIX-CONNECT:"/$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
          '';
      };
    in
    {
      exec-once = mkIf (cfg.autoHideWorkspaces != [ ]) [ (getExe workspaceAutoToggle) ];
      bind = [
        # Toggle active monitor bar
        "${modKey}, B, exec, ${toggleActiveMonitorBar}"
        # Toggle all bars
        "${modKey}SHIFT, B, exec, ${systemctl} kill --user --signal=SIGUSR1 waybar"
        # Restart waybar
        "${modKey}SHIFTCONTROL, B, exec, ${systemctl} restart --user waybar"
      ];
    };
}
