{ lib
, pkgs
, config
, inputs
, hostname
, ...
}:
let
  inherit (lib) mkIf utils;
  inherit (inputs.nix-resources.secrets) fqDomain;
  inherit (config.modules.services) caddy;
  cfg = config.modules.services.unifi;
in
mkIf cfg.enable
{
  assertions = utils.asserts [
    (hostname == "homelab")
    "Unifi is only intended to work on host 'homelab'"
    caddy.enable
    "Frigate requires Caddy to be enabled"
  ];

  services.unifi = {
    enable = true;
    openFirewall = false;
    unifiPackage = pkgs.unifi8;
    # WARN: Mongodb is not in cachix due to its license so has to be built from
    # source. It takes a considerable amount of time (~1 hour) and requires
    # more memory than my tmpfs has space for. A solution to
    # https://github.com/NixOS/nixpkgs/issues/293114 would make this a
    # non-issue but, for now, best solution I've found is to temporarily add
    # /tmp to impermanence, reboot, build, and then remove /tmp again. Pretty
    # annoying.

    # WARN: Be careful when changing mongodb versions as mongodb requires
    # manual intervention to migrate. Safest method is to export a unifi
    # backup, clear /var/lib/unifi and then restore from backup.
    mongodbPackage = pkgs.mongodb-6_0;
  };

  networking.firewall = {
    # https://help.ubnt.com/hc/en-us/articles/218506997
    allowedTCPPorts = [
      8080 # Device communication
      6789 # UniFi mobile speed test
    ];
    allowedUDPPorts = [
      10001 # Device discovery
    ];
  };

  # Unifi module has good default systemd hardening

  services.caddy.virtualHosts."unifi.${fqDomain}".extraConfig = ''
    import lan_only
    reverse_proxy https://127.0.0.1:${toString cfg.port} {
      # We have to allow insecure HTTPS because unifi forcefully enables TLS
      # with an invalid cert.
      transport http {
        tls
        tls_insecure_skip_verify
      }
    }
  '';

  # WARN: Auto-backups have to be configured in the UI
  backups.unifi = {
    paths = [ "/var/lib/unifi/data/backup/autobackup" ];
  };

  persistence.directories = [{
    directory = "/var/lib/unifi";
    user = "unifi";
    group = "unifi";
    mode = "750";
  }];

  virtualisation.vmVariant = {
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
