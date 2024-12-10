lib: pkgs: self:
let
  inherit (pkgs) callPackage;
in
{
  modernx = callPackage ./modernx.nix { };
  filen-desktop = callPackage ./filen-desktop.nix { };
  ctrld = callPackage ./ctrld.nix { };
  frigate-hass-card = callPackage ./frigate-hass-card.nix { };
  frigate-blueprint = callPackage ./frigate-blueprint.nix { };
  thermal-comfort = pkgs.home-assistant.python.pkgs.callPackage ./thermal-comfort.nix { };
  thermal-comfort-icons = callPackage ./thermal-comfort-icons.nix { };
  beammp-server = callPackage ./beammp-server { };
  beammp-launcher = callPackage ./beammp-launcher.nix { };
  heatmiser = pkgs.home-assistant.python.pkgs.callPackage ./heatmiser.nix { };
  daikin-onecta = pkgs.home-assistant.python.pkgs.callPackage ./daikin-onecta.nix { };
  multiviewer-for-f1 = callPackage ./multiviewer-for-f1.nix { };
  hyprpy = pkgs.python3Packages.callPackage ./hyprpy.nix { };
  formulaone-card = callPackage ./formulaone-card.nix { };
  app2unit = callPackage ./app2unit.nix { };
  microfetch = lib.${lib.ns}.addPatches pkgs.microfetch [ ../patches/microfetchIcon.patch ];
}
// import ./installers.nix lib self
