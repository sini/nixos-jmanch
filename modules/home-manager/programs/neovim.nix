{ lib
, pkgs
, config
, inputs
, osConfig'
, ...
}:
let
  inherit (lib) mkIf optionalString optional;
  inherit (config.modules.desktop.services) darkman;
  cfg = config.modules.programs.neovim;
in
mkIf cfg.enable
{
  home.packages = optional cfg.neovide.enable pkgs.neovide;

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      # Runtime dependendies
      fzf
      ripgrep
      gnumake
      gcc
      luajit

      # Language servers
      lua-language-server
      nil
      nixd

      # Formatters
      nixpkgs-fmt
      stylua

      # NOTE: These 'extra' lsp and formatters should be installed on a
      # per-project basis using nix shell

      # clang-tools
      # ltex-ls
      # omnisharp-roslyn
      # matlab-language-server
      # prettierd
      # black
    ];

    # Some treesitter parsers need this library
    extraWrapperArgs = [
      "--suffix"
      "LD_LIBRARY_PATH"
      ":"
      "${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
    ];
  };

  xdg.configFile."nvim".source = inputs.neovim-config.outPath;

  # For conditional nix-specific config in nvim config
  home.sessionVariables = {
    NIX_NEOVIM = 1;
    NIX_NEOVIM_DARKMAN = if darkman.enable then 1 else 0;
  };

  xdg.mimeApps = mkIf (osConfig'.modules.system.desktop.enable or false) {
    defaultApplications = {
      "text/plain" = [ "nvim.desktop" ];
    };
  };

  programs.zsh.initExtra =
    let
      inherit (config.modules.programs) alacritty;
    in
    optionalString alacritty.enable /*bash*/ ''
      # Disables alacritty opacity when launching nvim
      nvim() {
        if [[ -z "$DISPLAY" ]]; then
          command nvim "$@"
        else
          alacritty msg config window.opacity=1; command nvim "$@"; alacritty msg config --reset
        fi
      }
    '';

  # Change theme of all active Neovim instances
  darkman.switchScripts.neovim = theme: /*bash*/ ''
    ls "$XDG_RUNTIME_DIR"/nvim.*.0 | xargs -I {} \
      nvim --server {} --remote-expr "execute('Sunset${if theme == "dark" then "Night" else "Day"}')"
  '';

  persistence.directories = [
    ".cache/nvim"
    ".local/share/nvim"
    ".local/state/nvim"
  ];
}
