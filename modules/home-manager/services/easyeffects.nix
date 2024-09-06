{
  ns,
  lib,
  pkgs,
  config,
  osConfig',
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    mkForce
    getExe'
    ;
  inherit (osConfig'.${ns}.system) audio;
  cfg = config.${ns}.services.easyeffects;
in
mkIf (cfg.enable && (audio.enable or true)) {
  assertions = lib.${ns}.asserts [
    (osConfig'.programs.dconf.enable or true)
    "Easyeffects requires dconf to be enabled"
  ];

  services.easyeffects.enable = true;
  systemd.user.services.easyeffects.Install.WantedBy = mkForce [ ];

  programs.waybar.settings.bar =
    let
      systemctl = getExe' pkgs.systemd "systemctl";
      notifySend = getExe pkgs.libnotify;
    in
    {
      pulseaudio = {
        "on-click-middle" = # bash
          ''
            ${systemctl} is-active --quiet --user easyeffects && {
              ${systemctl} stop --user easyeffects
              ${notifySend} --urgency=low -t 3000 'Easyeffects disabled'
            } || {
              ${systemctl} start --user easyeffects
              ${notifySend} --urgency=low -t 3000 'Easyeffects enabled'
            }
          '';
      };
    };

  xdg.configFile = {
    "easyeffects/input/improved-microphone.json".text = # json
      ''
        {
          "input": {
            "blocklist": [],
            "compressor#0": {
              "attack": 5.0,
              "boost-amount": 6.0,
              "boost-threshold": -72.0,
              "bypass": false,
              "dry": -100.0,
              "hpf-frequency": 10.0,
              "hpf-mode": "off",
              "input-gain": 0.0,
              "knee": -6.0,
              "lpf-frequency": 20000.0,
              "lpf-mode": "off",
              "makeup": 0.0,
              "mode": "Downward",
              "output-gain": 0.0,
              "ratio": 4.0,
              "release": 75.0,
              "release-threshold": -40.0,
              "sidechain": {
                "lookahead": 0.0,
                "mode": "RMS",
                "preamp": 0.0,
                "reactivity": 10.0,
                "source": "Middle",
                "stereo-split-source": "Left/Right",
                "type": "Feed-forward"
              },
              "stereo-split": false,
              "threshold": -20.0,
              "wet": 0.0
            },
            "deesser#0": {
              "bypass": false,
              "detection": "RMS",
              "f1-freq": 3000.0,
              "f1-level": -6.0,
              "f2-freq": 5000.0,
              "f2-level": -6.0,
              "f2-q": 1.5000000000000004,
              "input-gain": 0.0,
              "laxity": 15,
              "makeup": 0.0,
              "mode": "Wide",
              "output-gain": 0.0,
              "ratio": 5.0,
              "sc-listen": false,
              "threshold": -20.0
            },
            "equalizer#0": {
              "balance": 0.0,
              "bypass": false,
              "input-gain": 0.0,
              "left": {
                "band0": {
                  "frequency": 50.0,
                  "gain": 3.0,
                  "mode": "RLC (BT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Hi-pass",
                  "width": 4.0
                },
                "band1": {
                  "frequency": 90.0,
                  "gain": 3.0,
                  "mode": "RLC (MT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Lo-shelf",
                  "width": 4.0
                },
                "band2": {
                  "frequency": 425.0,
                  "gain": -2.0,
                  "mode": "BWC (MT)",
                  "mute": false,
                  "q": 0.9999999999999998,
                  "slope": "x2",
                  "solo": false,
                  "type": "Bell",
                  "width": 4.0
                },
                "band3": {
                  "frequency": 3500.0,
                  "gain": 3.0,
                  "mode": "BWC (BT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x2",
                  "solo": false,
                  "type": "Bell",
                  "width": 4.0
                },
                "band4": {
                  "frequency": 9000.0,
                  "gain": 2.0,
                  "mode": "LRX (MT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Hi-shelf",
                  "width": 4.0
                }
              },
              "mode": "IIR",
              "num-bands": 5,
              "output-gain": 0.0,
              "pitch-left": 0.0,
              "pitch-right": 0.0,
              "right": {
                "band0": {
                  "frequency": 50.0,
                  "gain": 3.0,
                  "mode": "RLC (BT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Hi-pass",
                  "width": 4.0
                },
                "band1": {
                  "frequency": 90.0,
                  "gain": 3.0,
                  "mode": "RLC (MT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Lo-shelf",
                  "width": 4.0
                },
                "band2": {
                  "frequency": 425.0,
                  "gain": -2.0,
                  "mode": "BWC (MT)",
                  "mute": false,
                  "q": 0.9999999999999998,
                  "slope": "x2",
                  "solo": false,
                  "type": "Bell",
                  "width": 4.0
                },
                "band3": {
                  "frequency": 3500.0,
                  "gain": 3.0,
                  "mode": "BWC (BT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x2",
                  "solo": false,
                  "type": "Bell",
                  "width": 4.0
                },
                "band4": {
                  "frequency": 9000.0,
                  "gain": 2.0,
                  "mode": "LRX (MT)",
                  "mute": false,
                  "q": 0.7,
                  "slope": "x1",
                  "solo": false,
                  "type": "Hi-shelf",
                  "width": 4.0
                }
              },
              "split-channels": false
            },
            "filter#0": {
              "balance": 0.0,
              "bypass": false,
              "equal-mode": "IIR",
              "frequency": 80.0,
              "gain": 0.0,
              "input-gain": 0.0,
              "mode": "RLC (BT)",
              "output-gain": 0.0,
              "quality": 0.7,
              "slope": "x2",
              "type": "High-pass",
              "width": 4.0
            },
            "limiter#0": {
              "alr": false,
              "alr-attack": 5.0,
              "alr-knee": 0.0,
              "alr-release": 50.0,
              "attack": 1.0,
              "bypass": false,
              "dithering": "16bit",
              "external-sidechain": false,
              "gain-boost": true,
              "input-gain": 0.0,
              "lookahead": 5.0,
              "mode": "Herm Wide",
              "output-gain": 0.0,
              "oversampling": "Half x2(2L)",
              "release": 5.0,
              "sidechain-preamp": 0.0,
              "stereo-link": 100.0,
              "threshold": -1.0
            },
            "plugins_order": [
              "rnnoise#0",
            "filter#0",
            "deesser#0",
            "compressor#0",
            "equalizer#0",
            "speex#0",
            "limiter#0"
            ],
            "rnnoise#0": {
              "bypass": false,
              "enable-vad": false,
              "input-gain": 0.0,
              "model-path": "",
              "output-gain": 0.0,
              "release": 20.0,
              "vad-thres": 50.0,
              "wet": 0.0
            },
            "speex#0": {
              "bypass": false,
              "enable-agc": false,
              "enable-denoise": false,
              "enable-dereverb": false,
              "input-gain": 0.0,
              "noise-suppression": -70,
              "output-gain": 0.0,
              "vad": {
                "enable": true,
                "probability-continue": 90,
                "probability-start": 95
              }
            }
          }
        }
      '';
  };
}
