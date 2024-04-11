{
  modules = {
    shell = {
      enable = true;
      sillyTools = true;
    };

    desktop = {
      windowManager = "Hyprland";

      hyprland = {
        tearing = true;
        # FIX: Direct scanout doesn't seem to work due to this error:
        # error: connector D-1: Failed to page-flip output: a page-flip is already pending
        directScanout = false;
        logging = false;
      };

      programs = {
        # TODO: Switch from swaylock to hyprlock
        swaylock.enable = true;
        hyprlock.enable = false;
        anyrun.enable = false;
        fuzzel.enable = true;
        swww.enable = true;
      };

      services = {
        waybar.enable = true;
        dunst.enable = true;
        wlsunset.enable = true;

        hypridle.enable = true;

        wallpaper = {
          randomise = true;
          randomiseFrequency = "*-*-* 05:00:00"; # 5am everyday
        };
      };
    };

    programs = {
      alacritty.enable = true;
      foot.enable = true;
      btop.enable = true;
      cava.enable = true;
      torBrowser.enable = true;
      git.enable = true;
      neovim.enable = true;
      spotify.enable = true;
      fastfetch.enable = true;
      discord.enable = true;
      obs.enable = true;
      vscode.enable = true;
      stremio.enable = true;
      mpv.enable = true;
      chatterino.enable = true;
      images.enable = true;
      anki.enable = true;
      zathura.enable = true;
      qbittorrent.enable = true;
      filenDesktop.enable = true;
      multiviewerF1.enable = true;

      firefox = {
        enable = true;
        runInRam = true;
      };

      gaming = {
        mangohud.enable = true;
        r2modman.enable = true;
        lutris.enable = true;
        prism-launcher.enable = true;
      };
    };

    services = {
      syncthing.enable = true;

      easyeffects = {
        enable = true;
      };
    };
  };
}
