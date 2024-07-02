{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chromium
    discord
  ];

  modules.programs = {
    firefox.enable = true;
    anki.enable = true;
    rnote.enable = true;
    multiviewerF1.enable = true;

    gaming = {
      mangohud.enable = true;
      prism-launcher.enable = true;
    };
  };
}
