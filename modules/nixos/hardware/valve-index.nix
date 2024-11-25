# Issues
# - OpenXR games using Proton do not currently work.
#   https://github.com/ValveSoftware/Proton/issues/7382
# - The input in some OpenVR games that use legacy controls (such as Boneworks)
#   does not work.
{
  ns,
  lib,
  pkgs,
  config,
  inputs,
  username,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    singleton
    ;
  inherit (config.${ns}.core) homeManager;
  inherit (config.${ns}.device) primaryMonitor gpu;
  inherit (config.${ns}.hardware) bluetooth;
  inherit (config.${ns}.system) audio;
  inherit (config.${ns}.programs.gaming) gamemode;
  inherit (config.${ns}.services) lact;
  cfg = config.${ns}.hardware.valve-index;
in
mkIf cfg.enable {
  assertions = lib.${ns}.asserts [
    homeManager.enable
    "Valve Index requires home manager to be enabled"
    gamemode.enable
    "Valve Index requires gamemode to be enabled"
    audio.enable
    "Valve Index requires audio to be enabled"
    (audio.defaultSource != null && audio.defaultSink != null)
    "Valve Index requires the default sink and source devices to be set"
    lact.enable
    "Valve Index requires lact to be enabled"
    bluetooth.enable
    "Valve Index requires bluetooth to be enabled"
  ];

  nixpkgs.overlays = [ inputs.nixpkgs-xr.overlays.default ];

  userPackages = [
    pkgs.index_camera_passthrough
    (pkgs.makeDesktopItem {
      name = "monado";
      desktopName = "Monado";
      type = "Application";
      exec = "${getExe' pkgs.systemd "systemctl"} start --user monado";
      icon = (
        pkgs.fetchurl {
          url = "https://gitlab.freedesktop.org/uploads/-/system/group/avatar/5604/monado_icon_medium.png";
          hash = "sha256-Wx4BBHjNyuboDVQt8yV0tKQNDny4EDwRBtMSk9XHNVA=";
        }
      );
    })
  ];

  ${ns} = {
    system.audio.alsaDeviceAliases = {
      ${cfg.audio.source} = "Valve Index";
      ${cfg.audio.sink} = "Valve Index";
    };

    # Enables asynchronous reprojection in SteamVR by allowing any application
    # to acquire high priority queues
    # https://github.com/NixOS/nixpkgs/issues/217119#issuecomment-2434353553
    hardware.graphics.amd.kernelPatches = mkIf (gpu.type == "amd") [
      (pkgs.fetchpatch2 {
        url = "https://github.com/Frogging-Family/community-patches/raw/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch";
        hash = "sha256-1wUIeBrUfmRSADH963Ax/kXgm9x7ea6K6hQ+bStniIY=";
      })
    ];
  };

  services.monado = {
    enable = true;
    highPriority = true;
    defaultRuntime = true;
  };

  systemd.user.services.monado =
    let
      lighthouse = getExe pkgs.lighthouse-steamvr;
      pactl = getExe' pkgs.pulseaudio "pactl";
      sleep = getExe' pkgs.coreutils "sleep";

      openvrPaths = pkgs.writeText "monado-openvrpaths" ''
        {
          "config": [
            "/home/${username}/.local/share/Steam/config"
          ],
          "external_drivers": null,
          "jsonid": "vrpathreg",
          "log": [
            "/home/${username}/.local/share/Steam/logs"
          ],
          "runtime": [
            "${pkgs.opencomposite}/lib/opencomposite"
          ],
          "version": 1
        }
      '';
    in
    {
      serviceConfig = {
        ExecStartPre = "-${pkgs.writeShellScript "monado-exec-start-pre" ''
          ln -sf "$XDG_CONFIG_HOME/openxr/1/active_runtime.json" ${
            config.environment.etc."xdg/openxr/1/active_runtime.json".source
          }
          ln -sf "$XDG_CONFIG_HOME/openvr/openvrpaths.vrpath" ${openvrPaths}

          if [ ! -f "/tmp/disable-lighthouse-control" ]; then
            ${lighthouse} --state on
          fi

          # Monado doesn't change audio devices so we have to do it manually
          ${pactl} set-default-source "${cfg.audio.source}"
          ${pactl} set-source-mute "${cfg.audio.source}" 1
          ${pactl} set-card-profile "${cfg.audio.card}" "${cfg.audio.profile}"

          # The sink device is available after the headset has powered on
          (${sleep} 10; ${pactl} set-default-sink "${cfg.audio.sink}") &
        ''}";

        ExecStopPost = "-${pkgs.writeShellScript "monado-exec-stop-post" ''
          ${pactl} set-default-source ${audio.defaultSource}
          ${pactl} set-default-sink ${audio.defaultSink}

          if [ ! -f "/tmp/disable-lighthouse-control" ]; then
            ${lighthouse} --state off
          fi

          rm -rf "$XDG_CONFIG_HOME"/{openxr,openvr}
        ''}";
      };

      environment = {
        # Environment variable reference:
        # https://monado.freedesktop.org/getting-started.html#environment-variables

        # Using defaults from envision lighthouse profile:
        # https://gitlab.com/gabmus/envision/-/blob/main/src/profiles/lighthouse.rs

        XRT_COMPOSITOR_SCALE_PERCENTAGE = "140"; # global super sampling
        XRT_COMPOSITOR_COMPUTE = "1";
        # These two enable a window that contains debug info and a mirror view
        # which monado calls a "peek window"
        XRT_DEBUG_GUI = "1";
        XRT_CURATED_GUI = "1";
        # Description I can't find the source of: Set to 1 to unlimit the
        # compositor refresh from a power of two of your HMD refresh, typically
        # provides a large performance boost
        U_PACING_APP_USE_MIN_FRAME_PERIOD = "1";

        # Display modes:
        # - 0: 2880x1600@90.00
        # - 1: 2880x1600@144.00
        # - 2: 2880x1600@120.02
        # - 3: 2880x1600@80.00
        XRT_COMPOSITOR_DESIRED_MODE = "0";

        # Use SteamVR tracking (requires calibration with SteamVR)
        STEAMVR_LH_ENABLE = "true";

        # Application launch envs:
        # SURVIVE_ envs are no longer needed
        # PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc for Steam applications

        # Per-app supersampling applied after global XRT_COMPOSITOR_SCALE_PERCENTAGE.
        # I think super sampling with global gives higher quality.
        # OXR_VIEWPORT_SCALE_PERCENTAGE=100

        # If using Lact on an AMD GPU can set GAMEMODE_CUSTOM_ARGS=vr when using
        # gamemoderun command to automatically enable the VR power profile

        # Baseline launch options for Steam games:
        # PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc GAMEMODE_CUSTOM_ARGS=vr gamemoderun %command%
      };
    };

  # Fix for audio cutting out when GPU is under load
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Troubleshooting#stuttering-audio-in-virtual-machine
  services.pipewire.wireplumber.extraConfig."99-valve-index"."monitor.alsa.rules" = singleton {
    matches = singleton {
      "node.name" = "${cfg.audio.sink}";
    };
    actions.update-props = {
      # This adds latency so set to minimum value that fixes problem
      "api.alsa.period-size" = 1024;
      "api.alsa.headroom" = 8192;
    };
  };

  hm = {
    ${ns}.desktop = {
      hyprland.namedWorkspaces.VR = "monitor:${primaryMonitor.name}";
      services.waybar.audioDeviceIcons.${cfg.audio.sink} = "";
    };

    desktop.hyprland.settings =
      let
        inherit (config.hm.${ns}.desktop.hyprland) modKey namedWorkspaceIDs;
      in
      {
        bind = [
          "${modKey}, Grave, workspace, ${namedWorkspaceIDs.VR}"
          "${modKey}SHIFT, Grave, movetoworkspace, ${namedWorkspaceIDs.VR}"
        ];

        windowrulev2 = [
          "workspace ${namedWorkspaceIDs.VR} silent, class:^(monado-service)$"
          "center, class:^(monado-service)$"
        ];
      };
  };
}
