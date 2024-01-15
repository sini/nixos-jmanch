{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = [
    ./ssh.nix
    ./desktop.nix
    ./audio.nix
    ./windows.nix
    ./networking.nix
    ./impermanence.nix
    ./virtualisation.nix
  ];

  options.modules.system = {

    ssh = {
      allowPasswordAuth = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable ssh password authentication";
      };
    };

    networking = {
      tcpOptimisations = mkEnableOption "TCP optimisations";
      firewall.enable = mkEnableOption "firewall";
      resolved.enable = mkEnableOption "Resolved";
      wireless.enable = mkEnableOption "wireless";
    };

    audio = {
      enable = mkEnableOption "Pipewire audio";
      extraAudioTools = mkEnableOption "extra audio tools including Easyeffects and Helvum";
      scripts = {
        toggleMic = mkOption {
          type = types.str;
          description = "Script for toggling microphone mute";
        };
      };
    };

    virtualisation = {
      enable = mkEnableOption "virtualisation";
    };

    windowsBootEntry = {
      enable = mkEnableOption "Windows boot menu entry";
    };

  };
}
