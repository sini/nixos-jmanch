{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (inputs.nix-resources.secrets) fqDomain;
  cfg = config.modules.programs.taskwarrior;
in
lib.mkIf cfg.enable {
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    colorTheme = "light-256";
    extraConfig = ''
      include $XDG_RUNTIME_DIR/agenix/taskwarriorSyncEncryption
      sync.server.url=https://tasks.${fqDomain}
      sync.server.client_id=${cfg.userUuid}

      # https://github.com/GothenburgBitFactory/taskwarrior/blob/2e3badbf991e726ba0f0c4b5bb6b243ea2dcdfc3/doc/man/taskrc.5.in#L489
      recurrence=${if cfg.primaryClient then "1" else "0"}
    '';
  };

  home.packages = [ pkgs.taskwarrior-tui ];

  persistence.directories = [
    ".local/share/task"
    ".local/share/taskwarrior-tui"
  ];
}
