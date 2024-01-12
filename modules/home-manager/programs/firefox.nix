{ lib
, config
, nixosConfig
, ...
}:
let
  binary = "${config.programs.firefox.package}/bin/firefox";
  cfg = config.modules.programs.firefox;
  desktopCfg = config.modules.desktop;
  # color = base:
  #   inputs.nix-colors.lib.conversions.hexToRGBString "," config.colorscheme.colors.${base};
in
lib.mkIf cfg.enable {
  # TODO: Move firefox into a folder and add my extension config files in there
  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;
        search = {
          force = true;
          default = "Google";
        };
        settings = {
          # General
          "general.autoScroll" = true;
          "extensions.pocket.enabled" = false;
          # Enable userChrome.css modifications
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # Enable hardware acceleration
          # Firefox only support VAAPI acceleration. This is natively supported
          # by AMD cards but NVIDIA cards need a translation library to go from
          # VDPAU to VAAPI.
          "media.ffmpeg.vaapi.enabled" = (nixosConfig.device.gpu.type != null);

          # Scrolling
          "mousewheel.default.delta_multiplier_x" = 95;
          "mousewheel.default.delta_multiplier_y" = 95;
          "mousewheel.default.delta_multiplier_z" = 95;
          "general.smoothScroll.lines.durationMaxMS" = 125;
          "general.smoothScroll.lines.durationMinMS" = 125;
          "general.smoothScroll.mouseWheel.durationMaxMS" = 200;
          "general.smoothScroll.mouseWheel.durationMinMS" = 100;
          "general.smoothScroll.other.durationMaxMS" = 125;
          "general.smoothScroll.other.durationMinMS" = 125;
          "general.smoothScroll.pages.durationMaxMS" = 125;
          "general.smoothScroll.pages.durationMinMS" = 125;
          "mousewheel.system_scroll_override_on_root_content.horizontal.factor" = 175;
          "mousewheel.system_scroll_override_on_root_content.vertical.factor" = 175;
          "toolkit.scrollbox.horizontalScrollDistance" = 6;
          "toolkit.scrollbox.verticalScrollDistance" = 2;

          # UI
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.newtabpage.activity-stream.feeds.system.topstories" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";

          # QOL
          "signon.rememberSignons" = false;
          "signon.management.page.breach-alerts.enabled" = false;
          "layout.word_select.eat_space_to_next_word" = false;
          "browser.download.useDownloadDir" = false;
          "browser.aboutConfig.showWarning" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "doms.forms.autocomplete.formautofill" = false;

          # Privacy
          "private.globalprivacycontrol.enabled" = true;
          "private.donottrackheader.enabled" = true;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.discovery.enabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "browser.ping-centre.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          "captivedetect.canonicalURL" = "";
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;
        };
        userChrome = /* css */ ''
          /* Source file https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/autohide_toolbox.css made available under Mozilla Public License v. 2.0
          See the above repository for updates as well as full license text. */

          /* Hide the whole toolbar area unless urlbar is focused or cursor is over the toolbar */
          /* Dimensions on non-Win10 OS probably needs to be adjusted */

          /* Compatibility options for hide_tabs_toolbar.css and tabs_on_bottom.css at the end of this file */

          :root{
            --uc-autohide-toolbox-delay: 200ms; /* Wait 0.1s before hiding toolbars */
            --uc-toolbox-rotation: 70deg;  /* This may need to be lower on mac - like 75 or so */
          }

          :root[sizemode="maximized"]{
            --uc-toolbox-rotation: 70deg;
          }

          @media {
            #navigator-toolbox:not(:-moz-lwtheme){ background-color: -moz-dialog !important; }
          }

          :root[sizemode="fullscreen"],
          #navigator-toolbox[inFullscreen]{ margin-top: 0 !important; }

          #navigator-toolbox{
            position: fixed !important;
            display: block;
            background-color: var(--lwt-accent-color,black) !important;
            transition: transform 82ms linear, opacity 82ms linear !important;
            transition-delay: var(--uc-autohide-toolbox-delay) !important;
            transform-origin: top;
            transform: rotateX(var(--uc-toolbox-rotation));
            opacity: 0;
            line-height: 0;
            z-index: 1;
            pointer-events: none;
          }

          #navigator-toolbox:hover,
          #navigator-toolbox:focus-within{
            transition-delay: 33ms !important;
            transform: rotateX(0);
            opacity: 1;
          }
          /* This ruleset is separate, because not having :has support breaks other selectors as well */
          #mainPopupSet:has(> #appMenu-popup:hover) ~ toolbox{
            transition-delay: 33ms !important;
            transform: rotateX(0);
            opacity: 1;
          }

          #navigator-toolbox > *{ line-height: normal; pointer-events: auto }

          #navigator-toolbox,
          #navigator-toolbox > *{
            width: 100vw;
            -moz-appearance: none !important;
          }

          /* These two exist for oneliner compatibility */
          #nav-bar{ width: var(--uc-navigationbar-width,100vw) }
          #TabsToolbar{ width: calc(100vw - var(--uc-navigationbar-width,0px)) }

          /* Don't apply transform before window has been fully created */
          :root:not([sessionrestored]) #navigator-toolbox{ transform:none !important }

          :root[customizing] #navigator-toolbox{
            position: relative !important;
            transform: none !important;
            opacity: 1 !important;
          }

          #navigator-toolbox[inFullscreen] > #PersonalToolbar,
          #PersonalToolbar[collapsed="true"]{ display: none }

          /* Uncomment this if tabs toolbar is hidden with hide_tabs_toolbar.css */
           /*#titlebar{ margin-bottom: -9px }*/

          /* Uncomment the following for compatibility with tabs_on_bottom.css - this isn't well tested though */
          /*
          #navigator-toolbox{ flex-direction: column; display: flex; }
          #titlebar{ order: 2 }
          */
        '';
      };
    };
  };

  impermanence.directories = [
    ".mozilla"
    ".cache/mozilla"
  ];

  desktop.hyprland.binds =
    lib.mkIf (desktopCfg.windowManager == "hyprland")
      [ "${desktopCfg.hyprland.modKey}, Backspace, exec, ${binary}" ];
}
# TODO: Either theme firefox with this or figure out how to change theme through GTK

# /* Source file https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/color_variable_template.css made available under Mozilla Public License v. 2.0
# See the above repository for updates as well as full license text. */
#
# /* You should enable any non-default theme for these to apply properly. Built-in dark and light themes should work */
# :root{
#   /* Popup panels */
#   --arrowpanel-background: rgb(${color "base02"}) !important;
#   --arrowpanel-border-color: rgb(${color "base00"}) !important;
#   --arrowpanel-color: rgb(${color "base05"}) !important;
#   --arrowpanel-dimmed: rgb(${color "base00"}) !important;
#   /* window and toolbar background */
#   --lwt-accent-color: rgb(${color "base02"}) !important;
#   --lwt-accent-color-inactive: rgb(${color "base03"}) !important;
#   --toolbar-bgcolor: rgb(${color "base00"}) !important;  
#   /* tabs with system theme - text is not controlled by variable */
#   --tab-selected-bgcolor: rgb(${color "base00"}) !important;
#   /* tabs with any other theme */
#   --lwt-text-color: rgb(${color "base05"}) !important;
#   --lwt-selected-tab-background-color: rgb(${color "base02"}) !important;
#   /* toolbar area */
#   --toolbarbutton-icon-fill: rgb(${color "base05"}) !important;
#   --lwt-toolbarbutton-hover-background: rgb(${color "base02"}) !important;
#   --lwt-toolbarbutton-active-background: rgb(${color "base03"}) !important;
#   /* urlbar */
#   --toolbar-field-border-color: rgb(${color "base02"}) !important;
#   --toolbar-field-focus-border-color: rgb(${color "base00"}) !important;
#   --urlbar-popup-url-color: rgb(${color "base02"}) !important;
#   /* urlbar Firefox 92+ */
#   --toolbar-field-background-color: rgb(${color "base05"}) !important;
#   --toolbar-field-focus-background-color: rgb(${color "base04"}) !important;
#   --toolbar-field-color: rgb(${color "base02"}) !important;
#   --toolbar-field-focus-color: rgb(${color "base05"}) !important;
#   /* sidebar - note the sidebar-box rule for the header-area */
#   --lwt-sidebar-background-color: rgb(${color "base02"}) !important;
#   --lwt-sidebar-text-color: rgb(${color "base05"}) !important;
# }
# /* line between nav-bar and tabs toolbar,
#     also fallback color for border around selected tab */
# #navigator-toolbox{ --lwt-tabs-border-color: rgb(${color "base02"}) !important; }
# /* Line above tabs */
# #tabbrowser-tabs{ --lwt-tab-line-color: rgb(${color "base00"}) !important; }
# /* the header-area of sidebar needs this to work */
# #sidebar-box{ --sidebar-background-color: rgb(${color "base00"}) !important; }
