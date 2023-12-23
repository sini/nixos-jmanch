{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Support 64 bit only
    # Unstable native wayland support
    (wine-wayland.override {wineBuild = "wine64";})

    # Helper for installing runtime libs
    winetricks
  ];

  environment.persistence."/persist".users.joshua = {
    directories = [
      ".local/share/wineprefixes"
    ];
  };
  environment.sessionVariables.WINEPREFIX = "$HOME/.local/share/wineprefixes/default";
}
